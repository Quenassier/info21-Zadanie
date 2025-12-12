-- Info21 v1.0 - Part 1:
CREATE DATABASE IF NOT EXISTS info21;
USE info21;

-- Peers: информация о студентах (никнейм и дата рождения)
CREATE TABLE IF NOT EXISTS Peers (
    Nickname VARCHAR(255) PRIMARY KEY,
    Birthday DATE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tasks: задания с возможной иерархией (ParentTask) и максимальным XP
CREATE TABLE IF NOT EXISTS Tasks (
    Title VARCHAR(255) PRIMARY KEY,
    ParentTask VARCHAR(255),
    MaxXP INT NOT NULL CHECK (MaxXP > 0),
    FOREIGN KEY (ParentTask) REFERENCES Tasks(Title) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Checks: фиксирует факт проверки задания студентом в определённую дату
CREATE TABLE IF NOT EXISTS Checks (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Peer VARCHAR(255) NOT NULL,
    Task VARCHAR(255) NOT NULL,
    Date DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname) ON DELETE CASCADE,
    FOREIGN KEY (Task) REFERENCES Tasks(Title) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- P2P: этапы peer-to-peer проверок (Start, Success, Failure)
CREATE TABLE IF NOT EXISTS P2P (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CheckID INT NOT NULL,
    CheckingPeer VARCHAR(255) NOT NULL,
    State ENUM('Start', 'Success', 'Failure') NOT NULL,
    Time TIME NOT NULL DEFAULT (CURRENT_TIME),
    FOREIGN KEY (CheckID) REFERENCES Checks(ID) ON DELETE CASCADE,
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verter: автоматическая проверка после успешной P2P
CREATE TABLE IF NOT EXISTS Verter (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CheckID INT NOT NULL,
    State ENUM('Start', 'Success', 'Failure') NOT NULL,
    Time TIME NOT NULL DEFAULT (CURRENT_TIME),
    FOREIGN KEY (CheckID) REFERENCES Checks(ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TransferredPoints: очки, передаваемые от проверяемого к проверяющему при успешной P2P
CREATE TABLE IF NOT EXISTS TransferredPoints (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CheckingPeer VARCHAR(255) NOT NULL,
    CheckedPeer VARCHAR(255) NOT NULL,
    PointsAmount INT NOT NULL CHECK (PointsAmount > 0),
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname) ON DELETE CASCADE,
    FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Friends: дружеские связи между студентами (ненаправленные пары)
CREATE TABLE IF NOT EXISTS Friends (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Peer1 VARCHAR(255) NOT NULL,
    Peer2 VARCHAR(255) NOT NULL,
    FOREIGN KEY (Peer1) REFERENCES Peers(Nickname) ON DELETE CASCADE,
    FOREIGN KEY (Peer2) REFERENCES Peers(Nickname) ON DELETE CASCADE,
    CHECK (Peer1 != Peer2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Recommendations: рекомендации студентов как проверяющих
CREATE TABLE IF NOT EXISTS Recommendations (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Peer VARCHAR(255) NOT NULL,
    RecommendedPeer VARCHAR(255) NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname) ON DELETE CASCADE,
    FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname) ON DELETE CASCADE,
    CHECK (Peer != RecommendedPeer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- XP: количество опыта, начисленного за успешное прохождение проверки
CREATE TABLE IF NOT EXISTS XP (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    CheckID INT NOT NULL,
    XPAmount INT NOT NULL CHECK (XPAmount > 0),
    FOREIGN KEY (CheckID) REFERENCES Checks(ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TimeTracking: фиксация входов и выходов студентов из кампуса
-- State: 1 = вход, 2 = выход
CREATE TABLE IF NOT EXISTS TimeTracking (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Peer VARCHAR(255) NOT NULL,
    Date DATE NOT NULL DEFAULT (CURRENT_DATE),
    Time TIME NOT NULL DEFAULT (CURRENT_TIME),
    State TINYINT NOT NULL CHECK (State IN (1, 2)),
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Индексы для ускорения частых запросов
CREATE INDEX idx_checks_peer ON Checks(Peer);               -- поиск проверок по студенту
CREATE INDEX idx_checks_task ON Checks(Task);               -- поиск проверок по заданию
CREATE INDEX idx_checks_date ON Checks(Date);               -- фильтрация по дате
CREATE INDEX idx_p2p_checkid ON P2P(CheckID);               -- связь P2P с проверкой
CREATE INDEX idx_verter_checkid ON Verter(CheckID);         -- связь Verter с проверкой
CREATE INDEX idx_xp_checkid ON XP(CheckID);                 -- получение XP по проверке
CREATE INDEX idx_timetracking_peer_date ON TimeTracking(Peer, Date); -- посещения по студенту и дате
