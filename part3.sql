-- Info21 v1.0 - Part 3: Запросы и представления для анализа данных
-- Всё что нужно, чтобы быстро получить нужную информацию из базы
USE info21;


-- Показывает, сколько всего очков один студент передал другому (агрегировано)
-- Вместо кучи записей — одна строка на пару: "ivan → petr: 5 очков"
DROP VIEW IF EXISTS v_transferred_points;

CREATE VIEW v_transferred_points AS
SELECT 
    tp.CheckingPeer AS Peer1,
    tp.CheckedPeer AS Peer2,
    SUM(tp.PointsAmount) AS PointsAmount
FROM TransferredPoints tp
GROUP BY tp.CheckingPeer, tp.CheckedPeer
ORDER BY tp.CheckingPeer, tp.CheckedPeer;


-- Кто сколько XP получил за какие задания
-- ник, задача, опыт
DROP VIEW IF EXISTS v_peer_xp;

CREATE VIEW v_peer_xp AS
SELECT 
    c.Peer,
    c.Task,
    x.XPAmount AS XP
FROM Checks c
JOIN XP x ON c.ID = x.CheckID
ORDER BY c.Peer, c.Task;


-- Функция: кто сегодня (или в указанную дату) зашёл в кампус, но так и не вышел
-- Возвращает строку вида "ivan, petr, anna"
DELIMITER $$

DROP FUNCTION IF EXISTS fnc_peers_not_left_campus$$

CREATE FUNCTION fnc_peers_not_left_campus(check_date DATE)
RETURNS TEXT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE result TEXT DEFAULT '';
    DECLARE done INT DEFAULT 0;
    DECLARE peer_name VARCHAR(255);
    
    -- Ищем студентов с записью входа (State=1), но без выхода (State=2) в тот же день
    DECLARE cur CURSOR FOR
        SELECT DISTINCT tt.Peer
        FROM TimeTracking tt
        WHERE tt.Date = IFNULL(check_date, CURDATE())
          AND tt.State = 1
          AND NOT EXISTS (
              SELECT 1
              FROM TimeTracking tt2
              WHERE tt2.Peer = tt.Peer
                AND tt2.Date = tt.Date
                AND tt2.State = 2
          )
        ORDER BY tt.Peer;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO peer_name;
        IF done THEN
            LEAVE read_loop;
        END IF;
        IF result != '' THEN
            SET result = CONCAT(result, ', ');
        END IF;
        SET result = CONCAT(result, peer_name);
    END LOOP;
    CLOSE cur;
    
    RETURN result;
END$$

DELIMITER ;


-- Альтернатива функции выше — представление, чтобы можно было фильтровать по дате в SQL
DROP VIEW IF EXISTS v_peers_not_left_campus;

CREATE VIEW v_peers_not_left_campus AS
SELECT DISTINCT tt.Peer, tt.Date
FROM TimeTracking tt
WHERE tt.State = 1
  AND NOT EXISTS (
      SELECT 1
      FROM TimeTracking tt2
      WHERE tt2.Peer = tt.Peer
        AND tt2.Date = tt.Date
        AND tt2.State = 2
  )
ORDER BY tt.Date DESC, tt.Peer;


-- Сколько очков у каждого студента "в чистом виде":
-- сколько получил (когда его проверяли) минус сколько отдал (когда проверял сам)
-- Положительное число = в плюсе, отрицательное = в минусе
DROP VIEW IF EXISTS v_peer_points_change;

CREATE VIEW v_peer_points_change AS
SELECT 
    Peer,
    SUM(PointsChange) AS PointsChange
FROM (
    -- Получил очки (когда его проверяли)
    SELECT CheckedPeer AS Peer, PointsAmount AS PointsChange
    FROM TransferredPoints
    
    UNION ALL
    
    -- Отдал очки (когда проверял других)
    SELECT CheckingPeer AS Peer, -PointsAmount AS PointsChange
    FROM TransferredPoints
) AS combined
GROUP BY Peer
ORDER BY PointsChange DESC;


-- Кого проверяют чаще всего?
DROP VIEW IF EXISTS v_most_checked_peer;

CREATE VIEW v_most_checked_peer AS
SELECT 
    c.Peer,
    COUNT(*) AS CheckCount
FROM Checks c
GROUP BY c.Peer
ORDER BY CheckCount DESC
LIMIT 1;


-- Какое задание даёт больше всего XP?
DROP VIEW IF EXISTS v_task_with_max_xp;

CREATE VIEW v_task_with_max_xp AS
SELECT 
    t.Title AS Task,
    t.MaxXP
FROM Tasks t
ORDER BY t.MaxXP DESC
LIMIT 1;


-- Сколько проверок проходило в каждый день
DROP VIEW IF EXISTS v_checks_by_date;

CREATE VIEW v_checks_by_date AS
SELECT 
    c.Date AS CheckDate,
    COUNT(*) AS CheckCount
FROM Checks c
GROUP BY c.Date
ORDER BY c.Date DESC;


-- Показать все успешные проверки конкретного студента:
-- какие задания сдал, когда и сколько XP получил
-- Учитывает и P2P, и Verter (если он был)
DELIMITER $$

DROP PROCEDURE IF EXISTS prc_peer_successful_checks$$

CREATE PROCEDURE prc_peer_successful_checks(IN peer_nickname VARCHAR(255))
BEGIN
    SELECT 
        c.Task,
        c.Date AS CheckDate,
        x.XPAmount
    FROM Checks c
    JOIN P2P p ON c.ID = p.CheckID
    LEFT JOIN Verter v ON c.ID = v.CheckID
    JOIN XP x ON c.ID = x.CheckID
    WHERE c.Peer = peer_nickname
      AND p.State = 'Success'
      AND (v.State IS NULL OR v.State = 'Success')  -- Verter не обязателен, но если есть — должен быть Success
    ORDER BY c.Date DESC;
END$$

DELIMITER ;


-- Кого рекомендуют проверять студенту? Возвращает список по его рекомендациям
DELIMITER $$

DROP PROCEDURE IF EXISTS prc_peer_recommendations$$

CREATE PROCEDURE prc_peer_recommendations(IN peer_nickname VARCHAR(255))
BEGIN
    SELECT r.RecommendedPeer
    FROM Recommendations r
    WHERE r.Peer = peer_nickname
    ORDER BY r.RecommendedPeer;
END$$

DELIMITER ;


-- Все успешные проверки в системе — удобно для отчётов или дашбордов
DROP VIEW IF EXISTS v_successful_checks;

CREATE VIEW v_successful_checks AS
SELECT 
    c.ID,
    c.Peer,
    c.Task,
    c.Date,
    x.XPAmount
FROM Checks c
JOIN P2P p ON c.ID = p.CheckID
LEFT JOIN Verter v ON c.ID = v.CheckID
JOIN XP x ON c.ID = x.CheckID
WHERE p.State = 'Success'
  AND (v.State IS NULL OR v.State = 'Success')
ORDER BY c.Date DESC, c.Peer;


-- Сводка по каждому студенту: сколько всего проверок, сколько прошло успешно, сколько XP набрано
DROP VIEW IF EXISTS v_peer_statistics;

CREATE VIEW v_peer_statistics AS
SELECT 
    p.Nickname,
    COUNT(DISTINCT c.ID) AS TotalChecks,
    COUNT(DISTINCT CASE WHEN p2p.State = 'Success' THEN c.ID END) AS SuccessfulChecks,
    COALESCE(SUM(x.XPAmount), 0) AS TotalXP
FROM Peers p
LEFT JOIN Checks c ON p.Nickname = c.Peer
LEFT JOIN P2P p2p ON c.ID = p2p.CheckID AND p2p.State = 'Success'
LEFT JOIN XP x ON c.ID = x.CheckID
GROUP BY p.Nickname
ORDER BY TotalXP DESC;
