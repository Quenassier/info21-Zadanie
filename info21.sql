-- Info21 v1.0 - Sample Data
USE info21;

-- Очистка существующих данных
-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE TABLE TimeTracking;
-- TRUNCATE TABLE XP;
-- TRUNCATE TABLE Recommendations;
-- TRUNCATE TABLE Friends;
-- TRUNCATE TABLE TransferredPoints;
-- TRUNCATE TABLE Verter;
-- TRUNCATE TABLE P2P;
-- TRUNCATE TABLE Checks;
-- TRUNCATE TABLE Tasks;
-- TRUNCATE TABLE Peers;
-- SET FOREIGN_KEY_CHECKS = 1;

-- 1. Добавление студентов (Peers)

INSERT INTO Peers (Nickname, Birthday) VALUES
('john_doe', '1990-01-15'),
('jane_smith', '1992-03-20'),
('bob_wilson', '1991-07-10'),
('alice_brown', '1993-11-05'),
('charlie_davis', '1994-05-22'),
('diana_miller', '1992-09-30');

-- 2. Добавление заданий (Tasks)

INSERT INTO Tasks (Title, ParentTask, MaxXP) VALUES
('C2_SimpleBashUtils', NULL, 250),
('C3_String+', 'C2_SimpleBashUtils', 500),
('C4_Math', 'C3_String+', 300),
('C5_Decimal', 'C4_Math', 350),
('C6_Matrix', 'C5_Decimal', 200),
('C7_SmartCalc', 'C6_Matrix', 500);

-- 3. Добавление друзей (Friends)

INSERT INTO Friends (Peer1, Peer2) VALUES
('john_doe', 'jane_smith'),
('bob_wilson', 'alice_brown'),
('john_doe', 'bob_wilson'),
('jane_smith', 'alice_brown'),
('charlie_davis', 'diana_miller'),
('john_doe', 'charlie_davis');

-- 4. Добавление рекомендаций (Recommendations)

INSERT INTO Recommendations (Peer, RecommendedPeer) VALUES
('john_doe', 'jane_smith'),
('jane_smith', 'bob_wilson'),
('bob_wilson', 'alice_brown'),
('alice_brown', 'john_doe'),
('charlie_davis', 'diana_miller'),
('diana_miller', 'jane_smith'),
('john_doe', 'bob_wilson');

-- 5. Добавление записей о посещениях (TimeTracking)

-- 2024-01-10
INSERT INTO TimeTracking (Peer, Date, Time, State) VALUES
('john_doe', '2024-01-10', '09:00:00', 1),   -- Вход
('john_doe', '2024-01-10', '18:00:00', 2),   -- Выход
('jane_smith', '2024-01-10', '10:00:00', 1), -- Вход (не вышла)
('bob_wilson', '2024-01-10', '08:30:00', 1),
('bob_wilson', '2024-01-10', '17:30:00', 2),
('alice_brown', '2024-01-10', '09:15:00', 1),
('alice_brown', '2024-01-10', '16:45:00', 2);

-- 2024-01-11
INSERT INTO TimeTracking (Peer, Date, Time, State) VALUES
('john_doe', '2024-01-11', '09:30:00', 1),
('john_doe', '2024-01-11', '17:00:00', 2),
('jane_smith', '2024-01-11', '10:15:00', 1),
('jane_smith', '2024-01-11', '18:30:00', 2),
('bob_wilson', '2024-01-11', '08:00:00', 1),
('bob_wilson', '2024-01-11', '19:00:00', 2),
('charlie_davis', '2024-01-11', '09:00:00', 1); -- Не вышел

-- 6. Добавление проверок (Checks)

INSERT INTO Checks (Peer, Task, Date) VALUES
('john_doe', 'C2_SimpleBashUtils', '2024-01-10'),
('jane_smith', 'C2_SimpleBashUtils', '2024-01-10'),
('bob_wilson', 'C2_SimpleBashUtils', '2024-01-11'),
('alice_brown', 'C2_SimpleBashUtils', '2024-01-11'),
('john_doe', 'C3_String+', '2024-01-11'),
('jane_smith', 'C3_String+', '2024-01-12');

-- 7. Добавление P2P проверок

-- Проверка 1: john_doe проверяет C2_SimpleBashUtils (Check ID = 1)
INSERT INTO P2P (CheckID, CheckingPeer, State, Time) VALUES
(1, 'jane_smith', 'Start', '10:00:00'),
(1, 'jane_smith', 'Success', '10:30:00');

-- Проверка 2: jane_smith проверяет C2_SimpleBashUtils (Check ID = 2)
INSERT INTO P2P (CheckID, CheckingPeer, State, Time) VALUES
(2, 'bob_wilson', 'Start', '11:00:00'),
(2, 'bob_wilson', 'Success', '11:45:00');

-- Проверка 3: bob_wilson проверяет C2_SimpleBashUtils (Check ID = 3)
INSERT INTO P2P (CheckID, CheckingPeer, State, Time) VALUES
(3, 'alice_brown', 'Start', '09:00:00'),
(3, 'alice_brown', 'Failure', '09:20:00');

-- Проверка 4: alice_brown проверяет C2_SimpleBashUtils (Check ID = 4)
INSERT INTO P2P (CheckID, CheckingPeer, State, Time) VALUES
(4, 'john_doe', 'Start', '14:00:00'),
(4, 'john_doe', 'Success', '14:40:00');

-- Проверка 5: john_doe проверяет C3_String+ (Check ID = 5)
INSERT INTO P2P (CheckID, CheckingPeer, State, Time) VALUES
(5, 'jane_smith', 'Start', '15:00:00'),
(5, 'jane_smith', 'Success', '16:00:00');

-- 8. Добавление проверок Verter

-- Verter проверка для Check ID = 1 (успешная)
INSERT INTO Verter (CheckID, State, Time) VALUES
(1, 'Start', '10:35:00'),
(1, 'Success', '10:40:00');

-- Verter проверка для Check ID = 2 (успешная)
INSERT INTO Verter (CheckID, State, Time) VALUES
(2, 'Start', '11:50:00'),
(2, 'Success', '11:55:00');

-- Verter проверка для Check ID = 4 (успешная)
INSERT INTO Verter (CheckID, State, Time) VALUES
(4, 'Start', '14:45:00'),
(4, 'Success', '14:50:00');

-- Verter проверка для Check ID = 5 (успешная)
INSERT INTO Verter (CheckID, State, Time) VALUES
(5, 'Start', '16:05:00'),
(5, 'Success', '16:10:00');

-- 9. Добавление XP

-- XP для успешных проверок

INSERT INTO XP (CheckID, XPAmount) VALUES
(1, 250),  -- john_doe, C2_SimpleBashUtils, полный XP
(2, 250),  -- jane_smith, C2_SimpleBashUtils, полный XP
(4, 200),  -- alice_brown, C2_SimpleBashUtils, частичный XP
(5, 500);  -- john_doe, C3_String+, полный XP

-- 10. Проверка данных

-- После выполнения скрипта проверьте данные:

-- SELECT COUNT(*) AS PeersCount FROM Peers;           -- Должно быть 6
-- SELECT COUNT(*) AS TasksCount FROM Tasks;           -- Должно быть 6
-- SELECT COUNT(*) AS FriendsCount FROM Friends;       -- Должно быть 6
-- SELECT COUNT(*) AS ChecksCount FROM Checks;         -- Должно быть 6
-- SELECT COUNT(*) AS P2PCount FROM P2P;               -- Должно быть 10
-- SELECT COUNT(*) AS VerterCount FROM Verter;         -- Должно быть 8
-- SELECT COUNT(*) AS XPCount FROM XP;                 -- Должно быть 4

-- Примечания:

-- Лучший способ - использовать процедуры из part2.sql:
-- CALL prc_add_p2p_check('john_doe', 'jane_smith', 'C2_SimpleBashUtils', 'Start', '10:00:00');
-- CALL prc_add_p2p_check('john_doe', 'jane_smith', 'C2_SimpleBashUtils', 'Success', '10:30:00');
-- CALL prc_add_verter_check('john_doe', 'C2_SimpleBashUtils', 'Start', '10:35:00');
-- CALL prc_add_verter_check('john_doe', 'C2_SimpleBashUtils', 'Success', '10:40:00');
