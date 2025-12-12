-- Info21 v1.0 - Part 2: Процедуры и триггеры
USE info21; -- база данных

-- Добавляет P2P-проверку. Поддерживает как начало (Start), так и завершение (Success/Failure).
-- При завершении с Success автоматически начисляются очки проверяющему.
DELIMITER $$

DROP PROCEDURE IF EXISTS prc_add_p2p_check$$

CREATE PROCEDURE prc_add_p2p_check(
    IN checked_peer VARCHAR(255),
    IN checking_peer VARCHAR(255),
    IN task VARCHAR(255),
    IN state VARCHAR(255),
    IN check_time TIME
)
BEGIN
    DECLARE check_id INT;
    
    -- Если что-то сломается — откатываем всё
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Гарантируем, что state — это одно из трёх допустимых значений
    IF state NOT IN ('Start', 'Success', 'Failure') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid state: Must be Start, Success, or Failure';
    END IF;
    
    -- Если это начало проверки — создаём запись в Checks и первую запись в P2P
    IF state = 'Start' THEN
        INSERT INTO Checks (Peer, Task, Date)
        VALUES (checked_peer, task, CURDATE());
        
        SET check_id = LAST_INSERT_ID();
        
        INSERT INTO P2P (CheckID, CheckingPeer, State, Time)
        VALUES (check_id, checking_peer, 'Start', IFNULL(check_time, CURTIME()));
    ELSE
        -- Ищем последнюю активную проверку (где был Start сегодня)
        -- Важно: проверяем по дате, чтобы не зацепить вчерашние проверки
        SELECT c.ID INTO check_id
        FROM Checks c
        JOIN P2P p ON c.ID = p.CheckID
        WHERE c.Peer = checked_peer
          AND c.Task = task
          AND p.CheckingPeer = checking_peer
          AND p.State = 'Start'
          AND c.Date = CURDATE()
        ORDER BY p.Time DESC
        LIMIT 1;
        
        IF check_id IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT('No Start check found for peer ', checked_peer, ', task ', task);
        END IF;
        
        -- Завершаем проверку
        INSERT INTO P2P (CheckID, CheckingPeer, State, Time)
        VALUES (check_id, checking_peer, state, IFNULL(check_time, CURTIME()));
        
        -- Если всё прошло успешно — даём +1 очко проверяющему
        IF state = 'Success' THEN
            INSERT IGNORE INTO TransferredPoints (CheckingPeer, CheckedPeer, PointsAmount)
            VALUES (checking_peer, checked_peer, 1);
        END IF;
    END IF;
    
    COMMIT;
END$$

DELIMITER ;


-- Добавляет проверку от Verter’а. Работает ТОЛЬКО после успешной P2P.
-- Не позволяет запустить Verter, если P2P ещё не завершена или провалена.
DELIMITER $$

DROP PROCEDURE IF EXISTS prc_add_verter_check$$

CREATE PROCEDURE prc_add_verter_check(
    IN checked_peer VARCHAR(255),
    IN task VARCHAR(255),
    IN state VARCHAR(255),
    IN check_time TIME
)
BEGIN
    DECLARE check_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    IF state NOT IN ('Start', 'Success', 'Failure') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid state: Must be Start, Success, or Failure';
    END IF;
    
    -- Ищем самую свежую успешную P2P-проверку за сегодня
    SELECT c.ID INTO check_id
    FROM Checks c
    JOIN P2P p ON c.ID = p.CheckID
    WHERE c.Peer = checked_peer
      AND c.Task = task
      AND p.State = 'Success'
      AND c.Date = CURDATE()
    ORDER BY p.Time DESC
    LIMIT 1;
    
    IF check_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT('No successful P2P check found for peer ', checked_peer, ', task ', task);
    END IF;
    
    -- Не даём дважды завершить Verter для одной проверки
    IF state IN ('Success', 'Failure') THEN
        IF EXISTS (
            SELECT 1 FROM Verter 
            WHERE CheckID = check_id 
            AND State IN ('Success', 'Failure')
        ) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Verter check already completed for this check';
        END IF;
    END IF;
    
    INSERT INTO Verter (CheckID, State, Time)
    VALUES (check_id, state, IFNULL(check_time, CURTIME()));
    
    COMMIT;
END$$

DELIMITER ;


-- Триггер: не пускает XP, если условия не соблюдены.
-- Проверяет три вещи:
-- 1. XP не больше, чем положено за задание.
-- 2. P2P-проверка завершена успешно.
-- 3. Если есть Verter — он тоже должен быть успешен.
DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_xp$$

CREATE TRIGGER trg_check_xp
BEFORE INSERT ON XP
FOR EACH ROW
BEGIN
    DECLARE max_xp INT;
    DECLARE check_status VARCHAR(255);
    
    -- Сколько максимум XP можно получить за это задание?
    SELECT t.MaxXP INTO max_xp
    FROM Tasks t
    JOIN Checks c ON t.Title = c.Task
    WHERE c.ID = NEW.CheckID;
    
    IF NEW.XPAmount > max_xp THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = CONCAT('XP amount (', NEW.XPAmount, ') exceeds maximum XP (', max_xp, ') for this task');
    END IF;
    
    -- Убедимся, что P2P прошла успешно
    SELECT p.State INTO check_status
    FROM P2P p
    WHERE p.CheckID = NEW.CheckID
      AND p.State IN ('Success', 'Failure')
    ORDER BY p.Time DESC
    LIMIT 1;
    
    IF check_status != 'Success' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot add XP: P2P check is not successful';
    END IF;
    
    -- Если Verter участвовал — он тоже должен сказать "Success"
    IF EXISTS (SELECT 1 FROM Verter WHERE CheckID = NEW.CheckID) THEN
        SELECT v.State INTO check_status
        FROM Verter v
        WHERE v.CheckID = NEW.CheckID
          AND v.State IN ('Success', 'Failure')
        ORDER BY v.Time DESC
        LIMIT 1;
        
        IF check_status != 'Success' THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Cannot add XP: Verter check is not successful';
        END IF;
    END IF;
END$$

DELIMITER ;


-- Автоматически начисляет очки при успешной P2P.
-- Триггер на случай, если кто-то вставит P2P вручную (минуя процедуру).
-- Проверяет, что перед Success был Start — иначе начислять нечего.
DELIMITER $$

DROP TRIGGER IF EXISTS trg_update_transferred_points$$

CREATE TRIGGER trg_update_transferred_points
AFTER INSERT ON P2P
FOR EACH ROW
BEGIN
    IF NEW.State = 'Success' THEN
        -- Убеждаемся, что Start уже был (и это не дубликат или ошибка)
        IF EXISTS (
            SELECT 1 FROM P2P
            WHERE CheckID = NEW.CheckID
              AND CheckingPeer = NEW.CheckingPeer
              AND State = 'Start'
              AND ID != NEW.ID  -- исключаем текущую запись
        ) THEN
            -- Даём +1 очко проверяющему
            -- INSERT IGNORE на случай, если очки уже были начислены (например, через процедуру)
            INSERT IGNORE INTO TransferredPoints (CheckingPeer, CheckedPeer, PointsAmount)
            SELECT NEW.CheckingPeer, c.Peer, 1
            FROM Checks c
            WHERE c.ID = NEW.CheckID;
        END IF;
    END IF;
END$$

DELIMITER ;
