-- CREATE Tables

-- User
CREATE TABLE User (
    UserID NUMERIC(8) PRIMARY KEY,
    FullName VARCHAR(50),
    Email VARCHAR(50) UNIQUE NOT NULL,
    UserName VARCHAR(20) UNIQUE NOT NULL,
    Pwd VARCHAR(255) NOT NULL,
    Position CHAR(1) DEFAULT 'U' NOT NULL, -- U: User, A: Admin
    ProfileSetting TEXT
);

-- League
CREATE TABLE League (
    LeagueID NUMERIC(8) PRIMARY KEY,
    LeagueName VARCHAR(100) NOT NULL,
    LeagueType CHAR(1) DEFAULT 'P' NOT NULL, -- P: Public, R: Private
    Commissioner NUMERIC(8),
    MaxNumber NUMERIC(2) DEFAULT 10 NOT NULL,
    DraftDate DATE,
    Sport VARCHAR(10) NOT NULL,
    FOREIGN KEY (Commissioner) REFERENCES User(UserID)
);

CREATE TABLE Team (
    TeamID NUMERIC(8) PRIMARY KEY,
    TeamName VARCHAR(25) NOT NULL,
    Manager NUMERIC(8),
    LeagueID NUMERIC(8),
    TotalPoints NUMERIC(6,2) DEFAULT 0.00,
    LeagueRanking NUMERIC(3),
    TeamStatus CHAR(1) DEFAULT 'A', -- A: Active, I: Inactive
    Sport CHAR(3) NOT NULL, -- 'FTB','BB','SB'
    FOREIGN KEY (Manager) REFERENCES User(UserID),
    FOREIGN KEY (LeagueID) REFERENCES League(LeagueID)
);

-- Draft
CREATE TABLE Draft (
    DraftID NUMERIC(8) PRIMARY KEY,
    LeagueID NUMERIC(8),
    DraftDate DATE,
    DraftOrder CHAR(1),  -- R: round-robin, S: snake
    DraftStatus CHAR(1) DEFAULT 'I', -- I: In Progress, C: Completed
    FOREIGN KEY (LeagueID) REFERENCES League(LeagueID)
);

-- Player
CREATE TABLE Player (
    PlayerID NUMERIC(8) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    PhotoURL VARCHAR(2048),
    Sport CHAR(3) NOT NULL, -- FTB(football), BB(basketball),SB(soccer)
    Position CHAR(3),
    RealTeam VARCHAR(50),
    FantasyPoints NUMERIC(6,2) DEFAULT 0.00,
    AvaiStatus CHAR(1) DEFAULT 'A', -- A: Available, U: Unavailable
    TeamID NUMERIC(8) DEFAULT NULL,
    DraftID NUMERIC(8) DEFAULT NULL,
    FOREIGN KEY (TeamID) REFERENCES Team(TeamID),
    FOREIGN KEY (DraftID) REFERENCES Draft(DraftID)
);

-- MatchDetail
CREATE TABLE MatchDetail (
    MatchID NUMERIC(8) PRIMARY KEY,
    MatchDate DATE,
    FinalScore VARCHAR(10) DEFAULT '0-0',
    Winner VARCHAR(100) DEFAULT 'Draw' -- Home, Away, Draw
);

-- MatchTeam
CREATE TABLE MatchTeam (
    MatchID NUMERIC(8),
    TeamID NUMERIC(8),
    HomeOrAway VARCHAR(5) DEFAULT 'Home', -- Home, Away
    PRIMARY KEY (MatchID, TeamID),
    FOREIGN KEY (MatchID) REFERENCES MatchDetail(MatchID),
    FOREIGN KEY (TeamID) REFERENCES Team(TeamID)
);

-- PlayerStats
CREATE TABLE PlayerStats (
    StatsID NUMERIC(10) PRIMARY KEY,
    PlayerID NUMERIC(8),
    GameDate DATE,
    PerformanceStats TEXT DEFAULT 'No Data',
    InjuryStatus CHAR(1) DEFAULT 'N', -- N: No, Y: Yes
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID)
);

-- MatchEvent
CREATE TABLE MatchEvent (
    MatchEventID NUMERIC(8) PRIMARY KEY,
    EventType VARCHAR(50) DEFAULT 'Unknown',
    EventTime TIME,
    PlayerID NUMERIC(8),
    MatchID NUMERIC(8),
    ImpactFantasyPoint NUMERIC(8,2) DEFAULT 0,
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID),
    FOREIGN KEY (MatchID) REFERENCES MatchDetail(MatchID)
);

-- Trade
CREATE TABLE Trade (
    TradeID NUMERIC(10) PRIMARY KEY,
    TradeDate DATE
);

-- PlayerTrade
CREATE TABLE PlayerTrade (
    TradeID NUMERIC(10),
    PlayerID NUMERIC(8),
    FromOrTo VARCHAR(5) DEFAULT 'From',
    PRIMARY KEY (TradeID, PlayerID),
    FOREIGN KEY (TradeID) REFERENCES Trade(TradeID),
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID)
);

-- TeamTrade
CREATE TABLE TeamTrade (
    TradeID NUMERIC(10),
    TeamID NUMERIC(8),
    InOrOut VARCHAR(5) DEFAULT 'Out',
    PRIMARY KEY (TradeID, TeamID),
    FOREIGN KEY (TradeID) REFERENCES Trade(TradeID),
    FOREIGN KEY (TeamID) REFERENCES Team(TeamID)
);

-- Waiver
CREATE TABLE Waiver (
    WaiverID NUMERIC(8) PRIMARY KEY,
    WaiverStatus CHAR(1) DEFAULT 'P', -- P: Pending, A: Approved
    WaiverPickupDate DATE,
    TeamID NUMERIC(8),
    PlayerID NUMERIC(8),
    FOREIGN KEY (TeamID) REFERENCES Team(TeamID),
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID)
);



DELIMITER //

CREATE TRIGGER trg_increment_league_id
BEFORE INSERT ON League
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(LeagueID), 0) + 1 INTO max_id FROM League;
    SET NEW.LeagueID = max_id;
END;
//

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_increment_team_id
BEFORE INSERT ON Team
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(TeamID), 0) + 1 INTO max_id FROM Team;
    SET NEW.TeamID = max_id;
END;
//

DELIMITER ;



DELIMITER ;

DROP TRIGGER IF EXISTS trg_increment_trade_id;

DELIMITER //

CREATE TRIGGER trg_increment_trade_id
BEFORE INSERT ON Trade
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(10);
    SELECT IFNULL(MAX(TradeID), 0) + 1 INTO max_id FROM Trade;
    SET NEW.TradeID = max_id;
    SET @new_trade_id = max_id; -- Save the new TradeID for PlayerTrade and TeamTrade
END;
//

DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_increment_user_id
BEFORE INSERT ON User
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(UserID), 0) + 1 INTO max_id FROM User;
    SET NEW.UserID = max_id;
END;
//

DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_increment_player_id
BEFORE INSERT ON Player
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(PlayerID), 0) + 1 INTO max_id FROM Player;
    SET NEW.PlayerID = max_id;
END;
//

DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_increment_waiver_id
BEFORE INSERT ON Waiver
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(WaiverID), 0) + 1 INTO max_id FROM Waiver;
    SET NEW.WaiverID = max_id;
END;
//

DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_increment_playerstats_id
BEFORE INSERT ON PlayerStats
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(StatsID), 0) + 1 INTO max_id FROM PlayerStats;
    SET NEW.StatsID = max_id;
END;
//

DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_increment_matchevent_id
BEFORE INSERT ON MatchEvent
FOR EACH ROW
BEGIN
    DECLARE max_id NUMERIC(8);
    SELECT IFNULL(MAX(MatchEventID), 0) + 1 INTO max_id FROM MatchEvent;
    SET NEW.MatchEventID = max_id;
END;
//

DELIMITER ;








-- INSERT Data


-- User

INSERT INTO User (UserID, FullName, Email, UserName, Pwd, ProfileSetting, Position)
VALUES
(1, 'John Doe', 'john.doe@example.com', 'johndoe', 'pbkdf2:sha256:1000000$MFvzUbu46opJnjh8$6bb9b5995e11f9534cb888a35b009e1e2845387b12eefec4eebe006028560884', 'Public', 'U'),
(2, 'Jane Smith', 'jane.smith@example.com', 'janesmith', 'pbkdf2:sha256:1000000$4c3aZaiRQqitsG1X$6f01235bc8c849d9bbacb4d810c0cc02c12e79806ed0d4000bee2fd20a9ab88c', 'Private', 'U'),
(3, 'Alice Johnson', 'alice.johnson@example.com', 'alicej', 'pbkdf2:sha256:1000000$w21fkJUwjPEBWZve$3d31d69569c294bcae7d1f8f2dc6454933f95dac7173a5fa99495d139c594f4d', 'Public', 'U'),
(4, 'Bob Brown', 'bob.brown@example.com', 'bobb', 'pbkdf2:sha256:1000000$XQRu3HgXHwVoRu9V$5930d1514bc7e928b11771c266ded5ce0778d95f390c7056d2bb0b77ba055c68', 'Public', 'U'),
(5, 'Charlie Davis', 'charlie.davis@example.com', 'charlied', 'pbkdf2:sha256:1000000$6t3jWUY3lAZ2IiAr$6a851f5a57fd5687f81bf336b5286bcdceb1283b1c7e22c1595a339c8208a25a', 'Private', 'U'),
(6, 'David Evans', 'david.evans@example.com', 'davidevans', 'pbkdf2:sha256:1000000$pCbms7FXPRWGp1k7$12ef1a392bf63808e38bc10f8e2c3cfca8d87e8083b44e616dfd32a6859b4c4a', 'Public', 'U'),
(7, 'Emma Wilson', 'emma.wilson@example.com', 'emmaw', 'pbkdf2:sha256:1000000$3EkjXlkTSu8EIOLv$82507edbe7da2f7db167894ac487b42414dc2a096d0069236202ce875e9fb50b', 'Private', 'U'),
(8, 'Frank Taylor', 'frank.taylor@example.com', 'frankt', 'pbkdf2:sha256:1000000$GgWSEfAoWqOzQFMU$b3f37b00b62c262127fc20bc995a54f6976eed87a8f57dbde0c8fa5318689c0c', 'Public', 'U'),
(9, 'Grace Lee', 'grace.lee@example.com', 'gracelee', 'pbkdf2:sha256:1000000$e1NzLMfL58lzgkFa$15a99941a6477193e92b9c3ad9fa0797f60ee3ec3761348cdf4110e7a0ae6f54', 'Private', 'U'),
(10, 'Henry Walker', 'henry.walker@example.com', 'henryw', 'pbkdf2:sha256:1000000$FzeMIrbMKQ07t7m2$8633c669843e4055da8ef86e4971acbf95c1b001fee629bc694d2fdab414b06a', 'Public', 'U'),
(11, 'Isabella Scott', 'isabella.scott@example.com', 'isabellas', 'pbkdf2:sha256:1000000$hwUrJj77yIMSG07H$a3039dfef827b16286e91aa0d9cf43e3e0de8b863b5eca04ed1ce5d4372e387b', 'Private', 'U'),
(12, 'Jack White', 'jack.white@example.com', 'jackw', 'pbkdf2:sha256:1000000$iBS6XtxqpBcUP1iC$e7aeae79e6362a8b3d92ad133332a6a99e854b177db17069c748d000b0d95288', 'Public', 'U');


-- League
INSERT INTO League (LeagueID, LeagueName, LeagueType, Commissioner, MaxNumber, DraftDate, Sport)
VALUES
(1, 'American Football League', 'P', 1, 12, '2024-07-25', 'FTB'),
(2, 'College Football Fantasy', 'R', 2, 25, '2024-01-02', 'FTB'),
(3, 'Local Football Tournament', 'P', 3, 8, '2024-02-27', 'FTB'),
(4, 'National Football League', 'P', 4, 10, '2024-01-15', 'FTB'),

(5, 'NCAA Basketball League', 'P', 5, 22, '2024-11-11', 'BB'),
(6, 'All-Star Basketball League', 'P', 6, 18, '2024-08-03', 'BB'),
(7, 'Elite Basketball League', 'R', 7, 20, '2024-10-01', 'BB'),
(8, 'International Basketball League', 'R', 8, 15, '2024-11-05', 'BB'),

(9, 'Champions Fantasy League', 'R', 9, 16, '2024-12-15', 'SB'),
(10, 'City Soccer League', 'P', 10, 20, '2024-03-12', 'SB'),
(11, 'Continental Soccer Cup', 'P', 11, 10, '2024-05-08', 'SB'),
(12, 'Euro Soccer Fantasy', 'P', 12, 14, '2024-06-30', 'SB');


-- Team
INSERT INTO Team (TeamID, TeamName, Manager, LeagueID, TotalPoints, LeagueRanking, TeamStatus, Sport)
VALUES
-- FTB 
(1, 'Thunderbolts', 1, 1, 1200, 1, 'A', 'FTB'),
(2, 'Storm Chasers', 2, 1, 1150, 2, 'A', 'FTB'),
(3, 'Mighty Eagles', 3, 1, 1100, 3, 'A', 'FTB'),
(4, 'Iron Giants', 4, 1, 1050, 4, 'A', 'FTB'),
(5, 'Golden Griffins', 5, 1, 1000, 5, 'A', 'FTB'),
(6, 'Shadow Wolves', 6, 1, 950, 6, 'A', 'FTB'),

(7, 'Fire Falcons', 7, 2, 1300, 1, 'A', 'FTB'),
(8, 'Steel Dragons', 8, 2, 1250, 2, 'A', 'FTB'),
(9, 'Blazing Suns', 9, 2, 1200, 3, 'A', 'FTB'),
(10, 'Electric Tigers', 10, 2, 1150, 4, 'A', 'FTB'),
(11, 'Silver Hawks', 11, 2, 1100, 5, 'A', 'FTB'),
(12, 'Mystic Phoenix', 12, 2, 1050, 6, 'A', 'FTB'),

(13, 'Frost Bears', 1, 3, 1400, 1, 'A', 'FTB'),
(14, 'Crystal Knights', 2, 3, 1350, 2, 'A', 'FTB'),
(15, 'Raging Bulls', 3, 3, 1300, 3, 'A', 'FTB'),
(16, 'Shadow Panthers', 4, 3, 1250, 4, 'A', 'FTB'),
(17, 'Thunder Sharks', 5, 3, 1200, 5, 'A', 'FTB'),
(18, 'Volcano Cobras', 6, 3, 1150, 6, 'A', 'FTB'),

(19, 'Lava Titans', 7, 4, 1500, 1, 'A', 'FTB'),
(20, 'Phantom Reapers', 8, 4, 1450, 2, 'A', 'FTB'),
(21, 'Inferno Foxes', 9, 4, 1400, 3, 'A', 'FTB'),
(22, 'Glacier Owls', 10, 4, 1350, 4, 'A', 'FTB'),
(23, 'Tempest Lions', 11, 4, 1300, 5, 'A', 'FTB'),
(24, 'Electric Lions', 12, 4, 1250, 6, 'A', 'FTB'),

-- BB 
(25, 'Golden Hoops', 1, 5, 2000, 1, 'A', 'BB'),
(26, 'Silver Dunkers', 2, 5, 1950, 2, 'A', 'BB'),
(27, 'Flying Ballers', 3, 5, 1900, 3, 'A', 'BB'),
(28, 'Shooting Stars', 4, 5, 1850, 4, 'A', 'BB'),
(29, 'Basket Titans', 5, 5, 1800, 5, 'A', 'BB'),
(30, 'Rebound Kings', 6, 5, 1750, 6, 'A', 'BB'),

(31, 'Fast Dribblers', 7, 6, 2100, 1, 'A', 'BB'),
(32, 'Jumping Jaguars', 8, 6, 2050, 2, 'A', 'BB'),
(33, 'Pivot Panthers', 9, 6, 2000, 3, 'A', 'BB'),
(34, 'Alley-oop Aces', 10, 6, 1950, 4, 'A', 'BB'),
(35, 'Hoop Dreams', 11, 6, 1900, 5, 'A', 'BB'),
(36, 'Backboard Breakers', 12, 6, 1850, 6, 'A', 'BB'),

(37, 'Dribble Wizards', 1, 7, 2200, 1, 'A', 'BB'),
(38, 'Crossover Kings', 2, 7, 2150, 2, 'A', 'BB'),
(39, 'Slam Dunkers', 3, 7, 2100, 3, 'A', 'BB'),
(40, 'Rim Runners', 4, 7, 2050, 4, 'A', 'BB'),
(41, 'Fast Breakers', 5, 7, 2000, 5, 'A', 'BB'),
(42, 'Court Conquerors', 6, 7, 1950, 6, 'A', 'BB'),

(43, 'Triple Threat', 7, 8, 2300, 1, 'A', 'BB'),
(44, 'Zone Defenders', 8, 8, 2250, 2, 'A', 'BB'),
(45, 'Paint Protectors', 9, 8, 2200, 3, 'A', 'BB'),
(46, 'Full Court Press', 10, 8, 2150, 4, 'A', 'BB'),
(47, 'Buzzer Beaters', 11, 8, 2100, 5, 'A', 'BB'),
(48, 'Overtime Winners', 12, 8, 2050, 6, 'A', 'BB'),

-- SB 
(49, 'Goal Scorers', 1, 9, 3000, 1, 'A', 'SB'),
(50, 'Penalty Kings', 2, 9, 2950, 2, 'A', 'SB'),
(51, 'Free Kick Masters', 3, 9, 2900, 3, 'A', 'SB'),
(52, 'Dribble Magicians', 4, 9, 2850, 4, 'A', 'SB'),
(53, 'Tackle Titans', 5, 9, 2800, 5, 'A', 'SB'),
(54, 'Corner Kick Aces', 6, 9, 2750, 6, 'A', 'SB'),

(55, 'Swift Strikers', 7, 10, 3100, 1, 'A', 'SB'),
(56, 'Defense Warriors', 8, 10, 3050, 2, 'A', 'SB'),
(57, 'Midfield Maestros', 9, 10, 3000, 3, 'A', 'SB'),
(58, 'Offside Legends', 10, 10, 2950, 4, 'A', 'SB'),
(59, 'Forward Leaders', 11, 10, 2900, 5, 'A', 'SB'),
(60, 'Goal Line Heroes', 12, 10, 2850, 6, 'A', 'SB'),

(61, 'Pass Masters', 1, 11, 3200, 1, 'A', 'SB'),
(62, 'Counter Attackers', 2, 11, 3150, 2, 'A', 'SB'),
(63, 'Set Piece Specialists', 3, 11, 3100, 3, 'A', 'SB'),
(64, 'Ball Control Experts', 4, 11, 3050, 4, 'A', 'SB'),
(65, 'Man Markers', 5, 11, 3000, 5, 'A', 'SB'),
(66, 'Dynamic Duos', 6, 11, 2950, 6, 'A', 'SB'),

(67, 'Attacking Stars', 7, 12, 3300, 1, 'A', 'SB'),
(68, 'Sweeper Keepers', 8, 12, 3250, 2, 'A', 'SB'),
(69, 'Wing Wizards', 9, 12, 3200, 3, 'A', 'SB'),
(70, 'Long Shot Experts', 10, 12, 3150, 4, 'A', 'SB'),
(71, 'Formation Masters', 11, 12, 3100, 5, 'A', 'SB'),
(72, 'Game Changers', 12, 12, 3050, 6, 'A', 'SB');



-- Draft
INSERT INTO Draft (DraftID, LeagueID, DraftDate, DraftOrder, DraftStatus)
VALUES
(1, 1, '2023-01-20', 'R', 'C'),
(2, 2, '2023-02-15', 'S', 'C'),
(3, 3, '2023-03-10', 'R', 'C'),
(4, 4, '2023-04-05', 'S', 'C'),
(5, 5, '2023-05-01', 'R', 'C'),
(6, 6, '2023-06-12', 'S', 'C'),
(7, 7, '2023-07-09', 'R', 'C'),
(8, 8, '2023-08-20', 'S', 'C'),
(9, 9, '2023-09-15', 'R', 'C'),
(10, 10, '2023-10-25', 'S', 'C'),
(11, 11, '2023-11-10', 'R', 'C'),
(12, 12, '2023-12-05', 'S', 'C'),
(13, 1, '2024-01-20', 'R', 'C'),
(14, 2, '2024-02-15', 'S', 'I'),
(15, 3, '2024-03-10', 'R', 'C'),
(16, 4, '2024-04-05', 'S', 'I'),
(17, 5, '2024-05-01', 'R', 'C'),
(18, 6, '2024-06-12', 'S', 'C'),
(19, 7, '2024-07-09', 'R', 'I'),
(20, 8, '2024-08-20', 'S', 'C'),
(21, 9, '2024-09-15', 'R', 'C'),
(22, 10, '2024-10-25', 'S', 'I'),
(23, 11, '2024-11-10', 'R', 'C'),
(24, 12, '2024-12-05', 'S', 'C');


-- Player
INSERT INTO Player (PlayerID, FullName, PhotoURL, Sport, Position, RealTeam, FantasyPoints, AvaiStatus, TeamID, DraftID)
VALUES

(1, 'Patrick Mahomes', '1.jpg', 'FTB', 'QB', 'Kansas City Chiefs', 320, 'A', 1, 1),
(2, 'Travis Kelce', '2.jpg', 'FTB', 'TE', 'Kansas City Chiefs', 300, 'A', 1, 1),
(3, 'Aaron Jones', '3.jpg', 'FTB', 'RB', 'Green Bay Packers', 290, 'A', 1, 1),
(4, 'Chris Godwin', '4.jpg', 'FTB', 'WR', 'Tampa Bay Buccaneers', 280, 'A', 1, 1),
(5, 'Evan McPherson', '5.jpg', 'FTB', 'K', 'Cincinnati Bengals', 270, 'A', 1, 1),

(6, 'Josh Allen', '6.jpg', 'FTB', 'QB', 'Buffalo Bills', 330, 'A', 2, 1),
(7, 'Stefon Diggs', '7.jpg', 'FTB', 'WR', 'Buffalo Bills', 310, 'A', 2, 1),
(8, 'James Cook', '8.jpg', 'FTB', 'RB', 'Buffalo Bills', 300, 'A', 2, 1),
(9, 'Dawson Knox', '9.jpg', 'FTB', 'TE', 'Buffalo Bills', 290, 'A', 2, 1),
(10, 'Tyler Bass', '10.jpg', 'FTB', 'K', 'Buffalo Bills', 280, 'A', 2, 1),

(11, 'Joe Burrow', '11.jpg', 'FTB', 'QB', 'Cincinnati Bengals', 310, 'A', 3, 1),
(12, 'JaMarr Chase', '12.jpg', 'FTB', 'WR', 'Cincinnati Bengals', 300, 'A', 3, 1),
(13, 'Joe Mixon', '13.jpg', 'FTB', 'RB', 'Cincinnati Bengals', 290, 'A', 3, 1),
(14, 'Hayden Hurst', '14.jpg', 'FTB', 'TE', 'Cincinnati Bengals', 280, 'A', 3, 1),
(15, 'Emma Thomas', '15.jpg', 'FTB', 'K', 'Cincinnati Bengals', 270, 'A', 3, 1),

(16, 'Jalen Hurts', '16.jpg', 'FTB', 'QB', 'Philadelphia Eagles', 350, 'A', 4, 1),
(17, 'AJ Brown', '17.jpg', 'FTB', 'WR', 'Philadelphia Eagles', 340, 'A', 4, 1),
(18, 'Miles Sanders', '18.jpg', 'FTB', 'RB', 'Philadelphia Eagles', 320, 'A', 4, 1),
(19, 'Dallas Goedert', '19.jpg', 'FTB', 'TE', 'Philadelphia Eagles', 310, 'A', 4, 1),
(20, 'Jake Elliott', '20.jpg', 'FTB', 'K', 'Philadelphia Eagles', 300, 'A', 4, 1),

(21, 'Dak Prescott', '21.jpg', 'FTB', 'QB', 'Dallas Cowboys', 330, 'A', 5, 1),
(22, 'CeeDee Lamb', '22.jpg', 'FTB', 'WR', 'Dallas Cowboys', 320, 'A', 5, 1),
(23, 'Tony Pollard', '23.jpg', 'FTB', 'RB', 'Dallas Cowboys', 310, 'A', 5, 1),
(24, 'Dalton Schultz', '24.jpg', 'FTB', 'TE', 'Dallas Cowboys', 300, 'A', 5, 1),
(25, 'Brett Maher', '25.jpg', 'FTB', 'K', 'Dallas Cowboys', 290, 'A', 5, 1),

(26, 'Kirk Cousins', '26.jpg', 'FTB', 'QB', 'Minnesota Vikings', 320, 'A', 6, 1),
(27, 'Justin Jefferson', '27.jpg', 'FTB', 'WR', 'Minnesota Vikings', 310, 'A', 6, 1),
(28, 'Dalvin Cook', '28.jpg', 'FTB', 'RB', 'Minnesota Vikings', 300, 'A', 6, 1),
(29, 'TJ Hockenson', '29.jpg', 'FTB', 'TE', 'Minnesota Vikings', 290, 'A', 6, 1),
(30, 'Greg Joseph', '30.jpg', 'FTB', 'K', 'Minnesota Vikings', 280, 'A', 6, 1),

(31, 'James Anderson', '31.jpg', 'FTB', 'QB', 'Kansas City Chiefs', 310, 'A', 7, 2),
(32, 'Emily Johnson', '32.jpg', 'FTB', 'TE', 'Kansas City Chiefs', 300, 'A', 7, 2),
(33, 'Michael Brown', '33.jpg', 'FTB', 'RB', 'Green Bay Packers', 290, 'A', 7, 2),
(34, 'William Wilson', '34.jpg', 'FTB', 'WR', 'Tampa Bay Buccaneers', 280, 'A', 7, 2),
(35, 'Benjamin Moore', '35.jpg', 'FTB', 'K', 'Cincinnati Bengals', 270, 'A', 7, 2),

(36, 'Alexander Harris', '36.jpg', 'FTB', 'QB', 'Buffalo Bills', 330, 'A', 8, 2),
(37, 'Isabella Clark', '37.jpg', 'FTB', 'WR', 'Buffalo Bills', 320, 'A', 8, 2),
(38, 'Daniel Lewis', '38.jpg', 'FTB', 'RB', 'Buffalo Bills', 310, 'A', 8, 2),
(39, 'Mia Walker', '39.jpg', 'FTB', 'TE', 'Buffalo Bills', 300, 'A', 8, 2),
(40, 'Matthew Scott', '40.jpg', 'FTB', 'K', 'Buffalo Bills', 290, 'A', 8, 2),

(41, 'Sophia Hall', '41.jpg', 'FTB', 'QB', 'Cincinnati Bengals', 320, 'A', 9, 2),
(42, 'David Allen', '42.jpg', 'FTB', 'WR', 'Cincinnati Bengals', 310, 'A', 9, 2),
(43, 'Ava Adams', '43.jpg', 'FTB', 'RB', 'Cincinnati Bengals', 300, 'A', 9, 2),
(44, 'Samuel Martin', '44.jpg', 'FTB', 'TE', 'Cincinnati Bengals', 290, 'A', 9, 2),
(45, 'Olivia Taylor', '45.jpg', 'FTB', 'K', 'Cincinnati Bengals', 280, 'A', 9, 2),

(46, 'Charlotte King', '46.jpg', 'FTB', 'QB', 'Philadelphia Eagles', 350, 'A', 10, 2),
(47, 'Christopher Young', '47.jpg', 'FTB', 'WR', 'Philadelphia Eagles', 340, 'A', 10, 2),
(48, 'Amelia Hill', '48.jpg', 'FTB', 'RB', 'Philadelphia Eagles', 330, 'A', 10, 2),
(49, 'Anthony Wright', '49.jpg', 'FTB', 'TE', 'Philadelphia Eagles', 320, 'A', 10, 2),
(50, 'Grace Green', '50.jpg', 'FTB', 'K', 'Philadelphia Eagles', 310, 'A', 10, 2),

-- Team11 (LeagueID=2, FTB)
(51, 'Matthew Stafford', '51.jpg', 'FTB', 'QB', 'Los Angeles Rams', 310, 'A', 11, 2),
(52, 'Cooper Kupp', '52.jpg', 'FTB', 'WR', 'Los Angeles Rams', 300, 'A', 11, 2),
(53, 'Cam Akers', '53.jpg', 'FTB', 'RB', 'Los Angeles Rams', 290, 'A', 11, 2),
(54, 'Tyler Higbee', '54.jpg', 'FTB', 'TE', 'Los Angeles Rams', 280, 'A', 11, 2),
(55, 'Matt Gay', '55.jpg', 'FTB', 'K', 'Los Angeles Rams', 270, 'A', 11, 2),

-- Team12 (LeagueID=2, FTB)
(56, 'Andrew Baker', '56.jpg', 'FTB', 'QB', 'Los Angeles Chargers', 320, 'A', 12, 2),
(57, 'Keenan Allen', '57.jpg', 'FTB', 'WR', 'Los Angeles Chargers', 310, 'A', 12, 2),
(58, 'Chloe Perez', '58.jpg', 'FTB', 'RB', 'Los Angeles Chargers', 300, 'A', 12, 2),
(59, 'Joshua Gonzalez', '59.jpg', 'FTB', 'WR', 'Los Angeles Chargers', 290, 'A', 12, 2),
(60, 'Dustin Hopkins', '60.jpg', 'FTB', 'K', 'Los Angeles Chargers', 280, 'A', 12, 2),

-- Team13 (LeagueID=3, FTB)
(61, 'Tom Brady', '61.jpg', 'FTB', 'QB', 'Tampa Bay Buccaneers', 330, 'A', 13, 3),
(62, 'Mike Evans', '62.jpg', 'FTB', 'WR', 'Tampa Bay Buccaneers', 320, 'A', 13, 3),
(63, 'Leonard Fournette', '63.jpg', 'FTB', 'RB', 'Tampa Bay Buccaneers', 310, 'A', 13, 3),
(64, 'Cameron Brate', '64.jpg', 'FTB', 'TE', 'Tampa Bay Buccaneers', 300, 'A', 13, 3),
(65, 'Ryan Succop', '65.jpg', 'FTB', 'K', 'Tampa Bay Buccaneers', 290, 'A', 13, 3),

-- Team14 (LeagueID=3, FTB)
(66, 'Derek Carr', '66.jpg', 'FTB', 'QB', 'Las Vegas Raiders', 320, 'A', 14, 3),
(67, 'Davante Adams', '67.jpg', 'FTB', 'WR', 'Las Vegas Raiders', 310, 'A', 14, 3),
(68, 'Josh Jacobs', '68.jpg', 'FTB', 'RB', 'Las Vegas Raiders', 300, 'A', 14, 3),
(69, 'Darren Waller', '69.jpg', 'FTB', 'TE', 'Las Vegas Raiders', 290, 'A', 14, 3),
(70, 'Daniel Carlson', '70.jpg', 'FTB', 'K', 'Las Vegas Raiders', 280, 'A', 14, 3),

-- Team15 (LeagueID=3, FTB)
(71, 'Kyler Murray', '71.jpg', 'FTB', 'QB', 'Arizona Cardinals', 310, 'A', 15, 3),
(72, 'DeAndre Hopkins', '72.jpg', 'FTB', 'WR', 'Arizona Cardinals', 300, 'A', 15, 3),
(73, 'James Conner', '73.jpg', 'FTB', 'RB', 'Arizona Cardinals', 290, 'A', 15, 3),
(74, 'Zach Ertz', '74.jpg', 'FTB', 'TE', 'Arizona Cardinals', 280, 'A', 15, 3),
(75, 'Matt Prater', '75.jpg', 'FTB', 'K', 'Arizona Cardinals', 270, 'A', 15, 3),

-- Team16 (LeagueID=3, FTB)
(76, 'Aaron Rodgers', '76.jpg', 'FTB', 'QB', 'Green Bay Packers', 330, 'A', 16, 3),
(77, 'Allen Lazard', '77.jpg', 'FTB', 'WR', 'Green Bay Packers', 310, 'A', 16, 3),
(78, 'Sarah Davis', '78.jpg', 'FTB', 'RB', 'Green Bay Packers', 300, 'A', 16, 3),
(79, 'Robert Tonyan', '79.jpg', 'FTB', 'TE', 'Green Bay Packers', 290, 'A', 16, 3),
(80, 'Mason Crosby', '80.jpg', 'FTB', 'K', 'Green Bay Packers', 280, 'A', 16, 3),

-- Team17 (LeagueID=3, FTB)
(81, 'Russell Wilson', '81.jpg', 'FTB', 'QB', 'Denver Broncos', 320, 'A', 17, 3),
(82, 'Courtland Sutton', '82.jpg', 'FTB', 'WR', 'Denver Broncos', 310, 'A', 17, 3),
(83, 'Javonte Williams', '83.jpg', 'FTB', 'RB', 'Denver Broncos', 300, 'A', 17, 3),
(84, 'Albert Okwuegbunam', '84.jpg', 'FTB', 'TE', 'Denver Broncos', 290, 'A', 17, 3),
(85, 'Brandon McManus', '85.jpg', 'FTB', 'K', 'Denver Broncos', 280, 'A', 17, 3),

-- Team18 (LeagueID=3, FTB)
(86, 'Matthew Ryan', '86.jpg', 'FTB', 'QB', 'Indianapolis Colts', 310, 'A', 18, 3),
(87, 'Michael Pittman Jr.', '87.jpg', 'FTB', 'WR', 'Indianapolis Colts', 300, 'A', 18, 3),
(88, 'Jonathan Taylor', '88.jpg', 'FTB', 'RB', 'Indianapolis Colts', 290, 'A', 18, 3),
(89, 'Mo Alie-Cox', '89.jpg', 'FTB', 'TE', 'Indianapolis Colts', 280, 'A', 18, 3),
(90, 'Rodrigo Blankenship', '90.jpg', 'FTB', 'K', 'Indianapolis Colts', 270, 'A', 18, 3),

-- Team19 (LeagueID=4, FTB)
(91, 'Lamar Jackson', '91.jpg', 'FTB', 'QB', 'Baltimore Ravens', 330, 'A', 19, 4),
(92, 'Rashod Bateman', '92.jpg', 'FTB', 'WR', 'Baltimore Ravens', 320, 'A', 19, 4),
(93, 'J.K. Dobbins', '93.jpg', 'FTB', 'RB', 'Baltimore Ravens', 310, 'A', 19, 4),
(94, 'Mark Andrews', '94.jpg', 'FTB', 'TE', 'Baltimore Ravens', 300, 'A', 19, 4),
(95, 'Justin Tucker', '95.jpg', 'FTB', 'K', 'Baltimore Ravens', 290, 'A', 19, 4),

-- Team20 (LeagueID=4, FTB)
(96, 'Justin Fields', '96.jpg', 'FTB', 'QB', 'Chicago Bears', 320, 'A', 20, 4),
(97, 'Darnell Mooney', '97.jpg', 'FTB', 'WR', 'Chicago Bears', 310, 'A', 20, 4),
(98, 'David Montgomery', '98.jpg', 'FTB', 'RB', 'Chicago Bears', 300, 'A', 20, 4),
(99, 'Cole Kmet', '99.jpg', 'FTB', 'TE', 'Chicago Bears', 290, 'A', 20, 4),
(100, 'Cairo Santos', '100.jpg', 'FTB', 'K', 'Chicago Bears', 280, 'A', 20, 4),

-- Team21-24 (LeagueID=4, FTB)
(101, 'Tua Tagovailoa', '101.jpg', 'FTB', 'QB', 'Miami Dolphins', 330, 'A', 21, 4),
(102, 'Tyreek Hill', '102.jpg', 'FTB', 'WR', 'Miami Dolphins', 320, 'A', 21, 4),
(103, 'Raheem Mostert', '103.jpg', 'FTB', 'RB', 'Miami Dolphins', 310, 'A', 21, 4),
(104, 'Durham Smythe', '104.jpg', 'FTB', 'TE', 'Miami Dolphins', 300, 'A', 21, 4),
(105, 'Jason Sanders', '105.jpg', 'FTB', 'K', 'Miami Dolphins', 290, 'A', 21, 4),

(106, 'Trevor Lawrence', '106.jpg', 'FTB', 'QB', 'Jacksonville Jaguars', 320, 'A', 22, 4),
(107, 'Christian Kirk', '107.jpg', 'FTB', 'WR', 'Jacksonville Jaguars', 310, 'A', 22, 4),
(108, 'Travis Etienne Jr.', '108.jpg', 'FTB', 'RB', 'Jacksonville Jaguars', 300, 'A', 22, 4),
(109, 'Evan Engram', '109.jpg', 'FTB', 'TE', 'Jacksonville Jaguars', 290, 'A', 22, 4),
(110, 'Lily Mitchell', '110.jpg', 'FTB', 'K', 'Jacksonville Jaguars', 280, 'A', 22, 4),

(111, 'Justin Herbert', '111.jpg', 'FTB', 'QB', 'Los Angeles Chargers', 340, 'A', 23, 4),
(112, 'Mike Williams', '112.jpg', 'FTB', 'WR', 'Los Angeles Chargers', 330, 'A', 23, 4),
(113, 'Austin Ekeler', '113.jpg', 'FTB', 'RB', 'Los Angeles Chargers', 320, 'A', 23, 4),
(114, 'Gerald Everett', '114.jpg', 'FTB', 'TE', 'Los Angeles Chargers', 310, 'A', 23, 4),
(115, 'Cameron Dicker', '115.jpg', 'FTB', 'K', 'Los Angeles Chargers', 300, 'A', 23, 4),

(116, 'Mac Jones', '116.jpg', 'FTB', 'QB', 'New England Patriots', 320, 'A', 24, 4),
(117, 'DeVante Parker', '117.jpg', 'FTB', 'WR', 'New England Patriots', 310, 'A', 24, 4),
(118, 'Rhamondre Stevenson', '118.jpg', 'FTB', 'RB', 'New England Patriots', 300, 'A', 24, 4),
(119, 'Hunter Henry', '119.jpg', 'FTB', 'TE', 'New England Patriots', 290, 'A', 24, 4),
(120, 'Nick Folk', '120.jpg', 'FTB', 'K', 'New England Patriots', 280, 'A', 24, 4),

-- Team25 (TeamID=25)
(121, 'LeBron James', '121.jpg', 'BB', 'FWD', 'Los Angeles Lakers', 380, 'A', 25, 5),
(122, 'Anthony Davis', '122.jpg', 'BB', 'CEN', 'Los Angeles Lakers', 370, 'A', 25, 5),
(123, 'Russell Westbrook', '123.jpg', 'BB', 'GUA', 'Los Angeles Lakers', 360, 'A', 25, 5),
(124, 'Austin Reaves', '124.jpg', 'BB', 'GUA', 'Los Angeles Lakers', 350, 'A', 25, 5),
(125, 'Dwight Howard', '125.jpg', 'BB', 'CEN', 'Los Angeles Lakers', 340, 'A', 25, 5),

-- Team26 (TeamID=26)
(126, 'Stephen Curry', '126.jpg', 'BB', 'GUA', 'Golden State Warriors', 400, 'A', 26, 5),
(127, 'Klay Thompson', '127.jpg', 'BB', 'GUA', 'Golden State Warriors', 390, 'A', 26, 5),
(128, 'Draymond Green', '128.jpg', 'BB', 'FWD', 'Golden State Warriors', 380, 'A', 26, 5),
(129, 'Andrew Wiggins', '129.jpg', 'BB', 'FWD', 'Golden State Warriors', 370, 'A', 26, 5),
(130, 'Kevon Looney', '130.jpg', 'BB', 'CEN', 'Golden State Warriors', 360, 'A', 26, 5),

-- Team27 (TeamID=27)
(131, 'Kevin Durant', '131.jpg', 'BB', 'FWD', 'Phoenix Suns', 420, 'A', 27, 5),
(132, 'Devin Booker', '132.jpg', 'BB', 'GUA', 'Phoenix Suns', 410, 'A', 27, 5),
(133, 'Chris Paul', '133.jpg', 'BB', 'GUA', 'Phoenix Suns', 400, 'A', 27, 5),
(134, 'Deandre Ayton', '134.jpg', 'BB', 'CEN', 'Phoenix Suns', 390, 'A', 27, 5),
(135, 'Mikal Bridges', '135.jpg', 'BB', 'FWD', 'Phoenix Suns', 380, 'A', 27, 5),

-- Team28 (TeamID=28)
(136, 'Giannis Antetokounmpo', '136.jpg', 'BB', 'FWD', 'Milwaukee Bucks', 430, 'A', 28, 5),
(137, 'Khris Middleton', '137.jpg', 'BB', 'FWD', 'Milwaukee Bucks', 420, 'A', 28, 5),
(138, 'Jrue Holiday', '138.jpg', 'BB', 'GUA', 'Milwaukee Bucks', 410, 'A', 28, 5),
(139, 'Brook Lopez', '139.jpg', 'BB', 'CEN', 'Milwaukee Bucks', 400, 'A', 28, 5),
(140, 'Bobby Portis', '140.jpg', 'BB', 'FWD', 'Milwaukee Bucks', 390, 'A', 28, 5),

-- Team29 (TeamID=29)
(141, 'Luka Doncic', '141.jpg', 'BB', 'GUA', 'Dallas Mavericks', 420, 'A', 29, 5),
(142, 'Kyrie Irving', '142.jpg', 'BB', 'GUA', 'Dallas Mavericks', 410, 'A', 29, 5),
(143, 'Tim Hardaway Jr.', '143.jpg', 'BB', 'GUA', 'Dallas Mavericks', 400, 'A', 29, 5),
(144, 'Christian Wood', '144.jpg', 'BB', 'CEN', 'Dallas Mavericks', 390, 'A', 29, 5),
(145, 'Dorian Finney-Smith', '145.jpg', 'BB', 'FWD', 'Dallas Mavericks', 380, 'A', 29, 5),

-- Team30 (TeamID=30)
(146, 'Jayson Tatum', '146.jpg', 'BB', 'FWD', 'Boston Celtics', 430, 'A', 30, 5),
(147, 'Jaylen Brown', '147.jpg', 'BB', 'FWD', 'Boston Celtics', 420, 'A', 30, 5),
(148, 'Marcus Smart', '148.jpg', 'BB', 'GUA', 'Boston Celtics', 410, 'A', 30, 5),
(149, 'Al Horford', '149.jpg', 'BB', 'CEN', 'Boston Celtics', 400, 'A', 30, 5),
(150, 'Robert Williams III', '150.jpg', 'BB', 'CEN', 'Boston Celtics', 390, 'A', 30, 5),

-- LeagueID=6 (BB)，Team31 - Team36
-- Team31 (TeamID=31)
(151, 'Joel Embiid', '151.jpg', 'BB', 'CEN', 'Philadelphia 76ers', 440, 'A', 31, 6),
(152, 'James Harden', '152.jpg', 'BB', 'GUA', 'Philadelphia 76ers', 430, 'A', 31, 6),
(153, 'Tyrese Maxey', '153.jpg', 'BB', 'GUA', 'Philadelphia 76ers', 420, 'A', 31, 6),
(154, 'Tobias Harris', '154.jpg', 'BB', 'FWD', 'Philadelphia 76ers', 410, 'A', 31, 6),
(155, 'PJ Tucker', '155.jpg', 'BB', 'FWD', 'Philadelphia 76ers', 400, 'A', 31, 6),

-- Team32 (TeamID=32)
(156, 'Ja Morant', '156.jpg', 'BB', 'GUA', 'Memphis Grizzlies', 420, 'A', 32, 6),
(157, 'Jaren Jackson Jr.', '157.jpg', 'BB', 'FWD', 'Memphis Grizzlies', 410, 'A', 32, 6),
(158, 'Desmond Bane', '158.jpg', 'BB', 'GUA', 'Memphis Grizzlies', 400, 'A', 32, 6),
(159, 'Dillon Brooks', '159.jpg', 'BB', 'FWD', 'Memphis Grizzlies', 390, 'A', 32, 6),
(160, 'Steven Adams', '160.jpg', 'BB', 'CEN', 'Memphis Grizzlies', 380, 'A', 32, 6),

-- Team33 (TeamID=33)
(161, 'Donovan Mitchell', '161.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 430, 'A', 33, 6),
(162, 'Darius Garland', '162.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 420, 'A', 33, 6),
(163, 'Evan Mobley', '163.jpg', 'BB', 'FWD', 'Cleveland Cavaliers', 410, 'A', 33, 6),
(164, 'Jarrett Allen', '164.jpg', 'BB', 'CEN', 'Cleveland Cavaliers', 400, 'A', 33, 6),
(165, 'Caris LeVert', '165.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 390, 'A', 33, 6),

-- Team34 (TeamID=34)
(166, 'DeMar DeRozan', '166.jpg', 'BB', 'FWD', 'Chicago Bulls', 420, 'A', 34, 6),
(167, 'Zach LaVine', '167.jpg', 'BB', 'GUA', 'Chicago Bulls', 410, 'A', 34, 6),
(168, 'Nikola Vucevic', '168.jpg', 'BB', 'CEN', 'Chicago Bulls', 400, 'A', 34, 6),
(169, 'Lonzo Ball', '169.jpg', 'BB', 'GUA', 'Chicago Bulls', 390, 'A', 34, 6),
(170, 'Patrick Williams', '170.jpg', 'BB', 'FWD', 'Chicago Bulls', 380, 'A', 34, 6),

-- Team35 (TeamID=35)
(171, 'Trae Young', '171.jpg', 'BB', 'GUA', 'Atlanta Hawks', 430, 'A', 35, 6),
(172, 'Dejounte Murray', '172.jpg', 'BB', 'GUA', 'Atlanta Hawks', 420, 'A', 35, 6),
(173, 'John Collins', '173.jpg', 'BB', 'FWD', 'Atlanta Hawks', 410, 'A', 35, 6),
(174, 'Clint Capela', '174.jpg', 'BB', 'CEN', 'Atlanta Hawks', 400, 'A', 35, 6),
(175, 'Bogdan Bogdanovic', '175.jpg', 'BB', 'GUA', 'Atlanta Hawks', 390, 'A', 35, 6),

-- Team36 (TeamID=36)
(176, 'Damian Lillard', '176.jpg', 'BB', 'GUA', 'Portland Trail Blazers', 440, 'A', 36, 6),
(177, 'Anfernee Simons', '177.jpg', 'BB', 'GUA', 'Portland Trail Blazers', 430, 'A', 36, 6),
(178, 'Jerami Grant', '178.jpg', 'BB', 'FWD', 'Portland Trail Blazers', 420, 'A', 36, 6),
(179, 'Jusuf Nurkic', '179.jpg', 'BB', 'CEN', 'Portland Trail Blazers', 410, 'A', 36, 6),
(180, 'Josh Hart', '180.jpg', 'BB', 'FWD', 'Portland Trail Blazers', 400, 'A', 36, 6),

-- LeagueID=7 (BB)，Team37 - Team42
-- Team37 (TeamID=37)
(181, 'Jimmy Butler', '181.jpg', 'BB', 'FWD', 'Miami Heat', 420, 'A', 37, 7),
(182, 'Bam Adebayo', '182.jpg', 'BB', 'CEN', 'Miami Heat', 410, 'A', 37, 7),
(183, 'Tyler Herro', '183.jpg', 'BB', 'GUA', 'Miami Heat', 400, 'A', 37, 7),
(184, 'Kyle Lowry', '184.jpg', 'BB', 'GUA', 'Miami Heat', 390, 'A', 37, 7),
(185, 'Victor Oladipo', '185.jpg', 'BB', 'GUA', 'Miami Heat', 380, 'A', 37, 7),

-- Team38 (TeamID=38)
(186, 'Jacob Carter', '186.jpg', 'BB', 'GUA', 'Phoenix Suns', 430, 'A', 38, 7),
(187, 'Zoe Turner', '187.jpg', 'BB', 'GUA', 'Phoenix Suns', 420, 'A', 38, 7),
(188, 'Ryan Ramirez', '188.jpg', 'BB', 'CEN', 'Phoenix Suns', 410, 'A', 38, 7),
(189, 'Ellie Phillips', '189.jpg', 'BB', 'FWD', 'Phoenix Suns', 400, 'A', 38, 7),
(190, 'Cameron Johnson', '190.jpg', 'BB', 'FWD', 'Phoenix Suns', 390, 'A', 38, 7),

-- Team39 (TeamID=39)
(191, 'Karl-Anthony Towns', '191.jpg', 'BB', 'CEN', 'Minnesota Timberwolves', 430, 'A', 39, 7),
(192, 'Anthony Edwards', '192.jpg', 'BB', 'GUA', 'Minnesota Timberwolves', 420, 'A', 39, 7),
(193, 'Rudy Gobert', '193.jpg', 'BB', 'CEN', 'Minnesota Timberwolves', 410, 'A', 39, 7),
(194, 'Angelo Russell', '194.jpg', 'BB', 'GUA', 'Minnesota Timberwolves', 400, 'A', 39, 7),
(195, 'Jaden McDaniels', '195.jpg', 'BB', 'FWD', 'Minnesota Timberwolves', 390, 'A', 39, 7),

-- Team40 (TeamID=40)
(196, 'Paul George', '196.jpg', 'BB', 'FWD', 'Los Angeles Clippers', 420, 'A', 40, 7),
(197, 'Kawhi Leonard', '197.jpg', 'BB', 'FWD', 'Los Angeles Clippers', 410, 'A', 40, 7),
(198, 'John Wall', '198.jpg', 'BB', 'GUA', 'Los Angeles Clippers', 400, 'A', 40, 7),
(199, 'Reggie Jackson', '199.jpg', 'BB', 'GUA', 'Los Angeles Clippers', 390, 'A', 40, 7),
(200, 'Ivica Zubac', '200.jpg', 'BB', 'CEN', 'Los Angeles Clippers', 380, 'A', 40, 7),

-- Team41 (TeamID=41)
(201, 'Nicholas Roberts', '201.jpg', 'BB', 'FWD', 'Chicago Bulls', 430, 'A', 41, 7),
(202, 'Madison Campbell', '202.jpg', 'BB', 'GUA', 'Chicago Bulls', 420, 'A', 41, 7),
(203, 'Ethan Parker', '203.jpg', 'BB', 'CEN', 'Chicago Bulls', 410, 'A', 41, 7),
(204, 'Scarlett Lee', '204.jpg', 'BB', 'GUA', 'Chicago Bulls', 400, 'A', 41, 7),
(205, 'Jonathan Rodriguez', '205.jpg', 'BB', 'FWD', 'Chicago Bulls', 390, 'A', 41, 7),

-- Team42 (TeamID=42)
(206, 'Donovan Lee', '206.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 420, 'A', 42, 7),
(207, 'Victoria Edwards', '207.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 410, 'A', 42, 7),
(208, 'Logan White', '208.jpg', 'BB', 'FWD', 'Cleveland Cavaliers', 400, 'A', 42, 7),
(209, 'Jarrett Lee', '209.jpg', 'BB', 'CEN', 'Cleveland Cavaliers', 390, 'A', 42, 7),
(210, 'Caris Zheng', '210.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 380, 'A', 42, 7),

-- LeagueID=8 (BB)，Team43 - Team44
-- Team43 (TeamID=43)
(211, 'Brandon Ingram', '211.jpg', 'BB', 'FWD', 'New Orleans Pelicans', 430, 'A', 43, 8),
(212, 'Zion Williamson', '212.jpg', 'BB', 'FWD', 'New Orleans Pelicans', 420, 'A', 43, 8),
(213, 'CJ McCollum', '213.jpg', 'BB', 'GUA', 'New Orleans Pelicans', 410, 'A', 43, 8),
(214, 'Jonas Valanciunas', '214.jpg', 'BB', 'CEN', 'New Orleans Pelicans', 400, 'A', 43, 8),
(215, 'Herbert Jones', '215.jpg', 'BB', 'FWD', 'New Orleans Pelicans', 390, 'A', 43, 8),

-- Team44 (TeamID=44)
(216, 'Bradley Beal', '216.jpg', 'BB', 'GUA', 'Washington Wizards', 420, 'A', 44, 8),
(217, 'Kristaps Porzingis', '217.jpg', 'BB', 'CEN', 'Washington Wizards', 410, 'A', 44, 8),
(218, 'Kyle Kuzma', '218.jpg', 'BB', 'FWD', 'Washington Wizards', 400, 'A', 44, 8),
(219, 'Daniel Gafford', '219.jpg', 'BB', 'CEN', 'Washington Wizards', 390, 'A', 44, 8),
(220, 'Monte Morris', '220.jpg', 'BB', 'GUA', 'Washington Wizards', 380, 'A', 44, 8),

-- Team45 (TeamID=45)
(221, 'Adam Foster', '221.jpg', 'BB', 'GUA', 'Portland Trail Blazers', 440, 'A', 45, 8),
(222, 'Lily Collins', '222.jpg', 'BB', 'GUA', 'Portland Trail Blazers', 430, 'A', 45, 8),
(223, 'Jason Sanders', '223.jpg', 'BB', 'FWD', 'Portland Trail Blazers', 420, 'A', 45, 8),
(224, 'Nora Murphy', '224.jpg', 'BB', 'CEN', 'Portland Trail Blazers', 410, 'A', 45, 8),
(225, 'Kevin Peterson', '225.jpg', 'BB', 'FWD', 'Portland Trail Blazers', 400, 'A', 45, 8),

-- Team46 (TeamID=46)
(226, 'Ruby Long', '226.jpg', 'BB', 'FWD', 'Miami Heat', 430, 'A', 46, 8),
(227, 'Bamy Xia', '227.jpg', 'BB', 'CEN', 'Miami Heat', 420, 'A', 46, 8),
(228, 'Thomas Ward', '228.jpg', 'BB', 'GUA', 'Miami Heat', 410, 'A', 46, 8),
(229, 'Harper Hughes', '229.jpg', 'BB', 'GUA', 'Miami Heat', 400, 'A', 46, 8),
(230, 'Dylan Cook', '230.jpg', 'BB', 'GUA', 'Miami Heat', 390, 'A', 46, 8),

-- Team47 (TeamID=47)
(231, 'Hannah Bennett', '231.jpg', 'BB', 'FWD', 'Chicago Bulls', 420, 'A', 47, 8),
(232, 'Caleb Morris', '232.jpg', 'BB', 'GUA', 'Chicago Bulls', 410, 'A', 47, 8),
(233, 'Natalie Ross', '233.jpg', 'BB', 'CEN', 'Chicago Bulls', 400, 'A', 47, 8),
(234, 'Owen Cooper', '234.jpg', 'BB', 'GUA', 'Chicago Bulls', 390, 'A', 47, 8),
(235, 'Lucy Morgan', '235.jpg', 'BB', 'FWD', 'Chicago Bulls', 380, 'A', 47, 8),

-- Team48 (TeamID=48)
(236, 'Lucas Cox', '236.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 430, 'A', 48, 8),
(237, 'Eleanor Evans', '237.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 420, 'A', 48, 8),
(238, 'Evan Zhang', '238.jpg', 'BB', 'FWD', 'Cleveland Cavaliers', 410, 'A', 48, 8),
(239, 'Henry Kelly', '239.jpg', 'BB', 'CEN', 'Cleveland Cavaliers', 400, 'A', 48, 8),
(240, 'Layla Diazy', '240.jpg', 'BB', 'GUA', 'Cleveland Cavaliers', 390, 'A', 48, 8),

-- LeagueID=9 (SB)，Team49 - Team54
-- Team49 (TeamID=49)
(241, 'Lionel Messi', '241.jpg', 'SB', 'FW', 'Inter Miami', 500, 'A', 49, 9),
(242, 'Sergio Busquets', '242.jpg', 'SB', 'MF', 'Inter Miami', 480, 'A', 49, 9),
(243, 'Jordi Alba', '243.jpg', 'SB', 'DF', 'Inter Miami', 470, 'A', 49, 9),
(244, 'Josef Martinez', '244.jpg', 'SB', 'FW', 'Inter Miami', 460, 'A', 49, 9),
(245, 'Drake Callender', '245.jpg', 'SB', 'GK', 'Inter Miami', 450, 'A', 49, 9),

-- Team50 (TeamID=50)
(246, 'Cristiano Ronaldo', '246.jpg', 'SB', 'FW', 'Al-Nassr', 500, 'A', 50, 9),
(247, 'Sadio Mane', '247.jpg', 'SB', 'FW', 'Al-Nassr', 480, 'A', 50, 9),
(248, 'Anderson Talisca', '248.jpg', 'SB', 'MF', 'Al-Nassr', 470, 'A', 50, 9),
(249, 'Luiz Gustavo', '249.jpg', 'SB', 'MF', 'Al-Nassr', 460, 'A', 50, 9),
(250, 'David Ospina', '250.jpg', 'SB', 'GK', 'Al-Nassr', 450, 'A', 50, 9),

-- Team51 (TeamID=51)
(251, 'Kylian Mbappe', '251.jpg', 'SB', 'FW', 'Paris Saint-Germain', 490, 'A', 51, 9),
(252, 'Neymar Jr', '252.jpg', 'SB', 'FW', 'Paris Saint-Germain', 480, 'A', 51, 9),
(253, 'Marco Verratti', '253.jpg', 'SB', 'MF', 'Paris Saint-Germain', 470, 'A', 51, 9),
(254, 'Marquinhos', '254.jpg', 'SB', 'DF', 'Paris Saint-Germain', 460, 'A', 51, 9),
(255, 'Gianluigi Donnarumma', '255.jpg', 'SB', 'GK', 'Paris Saint-Germain', 450, 'A', 51, 9),

-- Team52 (TeamID=52)
(256, 'Robert Lewandowski', '256.jpg', 'SB', 'FW', 'FC Barcelona', 490, 'A', 52, 9),
(257, 'Pedri', '257.jpg', 'SB', 'MF', 'FC Barcelona', 480, 'A', 52, 9),
(258, 'Frenkie de Jong', '258.jpg', 'SB', 'MF', 'FC Barcelona', 470, 'A', 52, 9),
(259, 'Jules Kounde', '259.jpg', 'SB', 'DF', 'FC Barcelona', 460, 'A', 52, 9),
(260, 'Marc-André ter Stegen', '260.jpg', 'SB', 'GK', 'FC Barcelona', 450, 'A', 52, 9),

-- Team53 (TeamID=53)
(261, 'Erling Haaland', '261.jpg', 'SB', 'FW', 'Manchester City', 500, 'A', 53, 9),
(262, 'Kevin De Bruyne', '262.jpg', 'SB', 'MF', 'Manchester City', 490, 'A', 53, 9),
(263, 'Phil Foden', '263.jpg', 'SB', 'MF', 'Manchester City', 480, 'A', 53, 9),
(264, 'Rúben Dias', '264.jpg', 'SB', 'DF', 'Manchester City', 470, 'A', 53, 9),
(265, 'Ederson Moraes', '265.jpg', 'SB', 'GK', 'Manchester City', 460, 'A', 53, 9),

-- Team54 (TeamID=54)
(266, 'Karim Benzema', '266.jpg', 'SB', 'FW', 'Al-Ittihad', 490, 'A', 54, 9),
(267, 'Golo Kanté', '267.jpg', 'SB', 'MF', 'Al-Ittihad', 480, 'A', 54, 9),
(268, 'Fabinho', '268.jpg', 'SB', 'MF', 'Al-Ittihad', 470, 'A', 54, 9),
(269, 'Ahmed Hegazi', '269.jpg', 'SB', 'DF', 'Al-Ittihad', 460, 'A', 54, 9),
(270, 'Marcelo Grohe', '270.jpg', 'SB', 'GK', 'Al-Ittihad', 450, 'A', 54, 9),

-- LeagueID=10 (SB)，Team55 - Team60
-- Team55 (TeamID=55)
(271, 'Mohamed Salah', '271.jpg', 'SB', 'FW', 'Liverpool', 480, 'A', 55, 10),
(272, 'Luis Díaz', '272.jpg', 'SB', 'FW', 'Liverpool', 470, 'A', 55, 10),
(273, 'Jordan Henderson', '273.jpg', 'SB', 'MF', 'Liverpool', 460, 'A', 55, 10),
(274, 'Virgil van Dijk', '274.jpg', 'SB', 'DF', 'Liverpool', 450, 'A', 55, 10),
(275, 'Alisson Becker', '275.jpg', 'SB', 'GK', 'Liverpool', 440, 'A', 55, 10),

-- Team56 (TeamID=56)
(276, 'Harry Kane', '276.jpg', 'SB', 'FW', 'Bayern Munich', 480, 'A', 56, 10),
(277, 'Thomas Müller', '277.jpg', 'SB', 'MF', 'Bayern Munich', 470, 'A', 56, 10),
(278, 'Jamal Musiala', '278.jpg', 'SB', 'MF', 'Bayern Munich', 460, 'A', 56, 10),
(279, 'Joshua Kimmich', '279.jpg', 'SB', 'DF', 'Bayern Munich', 450, 'A', 56, 10),
(280, 'Manuel Neuer', '280.jpg', 'SB', 'GK', 'Bayern Munich', 440, 'A', 56, 10),

-- Team57 (TeamID=57)
(281, 'Vinícius Júnior', '281.jpg', 'SB', 'FW', 'Real Madrid', 490, 'A', 57, 10),
(282, 'Luka Modrić', '282.jpg', 'SB', 'MF', 'Real Madrid', 480, 'A', 57, 10),
(283, 'Toni Kroos', '283.jpg', 'SB', 'MF', 'Real Madrid', 470, 'A', 57, 10),
(284, 'David Alaba', '284.jpg', 'SB', 'DF', 'Real Madrid', 460, 'A', 57, 10),
(285, 'Thibaut Courtois', '285.jpg', 'SB', 'GK', 'Real Madrid', 450, 'A', 57, 10),

-- Team58 (TeamID=58)
(286, 'Marcus Rashford', '286.jpg', 'SB', 'FW', 'Manchester United', 480, 'A', 58, 10),
(287, 'Bruno Fernandes', '287.jpg', 'SB', 'MF', 'Manchester United', 470, 'A', 58, 10),
(288, 'Casemiro', '288.jpg', 'SB', 'MF', 'Manchester United', 460, 'A', 58, 10),
(289, 'Raphaël Varane', '289.jpg', 'SB', 'DF', 'Manchester United', 450, 'A', 58, 10),
(290, 'David de Gea', '290.jpg', 'SB', 'GK', 'Manchester United', 440, 'A', 58, 10),

-- Team59 (TeamID=59)
(291, 'Sadio Mané', '291.jpg', 'SB', 'FW', 'Al-Nassr', 480, 'A', 59, 10),
(292, 'André Carrillo', '292.jpg', 'SB', 'MF', 'Al-Hilal', 470, 'A', 59, 10),
(293, 'Matheus Pereira', '293.jpg', 'SB', 'MF', 'Al-Hilal', 460, 'A', 59, 10),
(294, 'Jang Hyun-soo', '294.jpg', 'SB', 'DF', 'Al-Hilal', 450, 'A', 59, 10),
(295, 'Abdullah Al-Mayouf', '295.jpg', 'SB', 'GK', 'Al-Hilal', 440, 'A', 59, 10),

-- Team60 (TeamID=60)
(296, 'Lila Fisher', '296.jpg', 'SB', 'FW', 'Al-Ittihad', 490, 'A', 60, 10),
(297, 'Brandon Reed', '297.jpg', 'SB', 'MF', 'Al-Ittihad', 480, 'A', 60, 10),
(298, 'Hazel Ortiz', '298.jpg', 'SB', 'MF', 'Al-Ittihad', 470, 'A', 60, 10),
(299, 'Tyler Howard', '299.jpg', 'SB', 'DF', 'Al-Ittihad', 460, 'A', 60, 10),
(300, 'Maya Patterson', '300.jpg', 'SB', 'GK', 'Al-Ittihad', 450, 'A', 60, 10),

-- LeagueID=11 (SB)，Team61 - Team66
-- Team61 (TeamID=61)
(301, 'Heung-Min Son', '301.jpg', 'SB', 'FW', 'Tottenham Hotspur', 480, 'A', 61, 11),
(302, 'James Maddison', '302.jpg', 'SB', 'MF', 'Tottenham Hotspur', 470, 'A', 61, 11),
(303, 'Pierre-Emile Højbjerg', '303.jpg', 'SB', 'MF', 'Tottenham Hotspur', 460, 'A', 61, 11),
(304, 'Cristian Romero', '304.jpg', 'SB', 'DF', 'Tottenham Hotspur', 450, 'A', 61, 11),
(305, 'Guglielmo Vicario', '305.jpg', 'SB', 'GK', 'Tottenham Hotspur', 440, 'A', 61, 11),

-- Team62 (TeamID=62)
(306, 'Bukayo Saka', '306.jpg', 'SB', 'FW', 'Arsenal', 490, 'A', 62, 11),
(307, 'Martin Ødegaard', '307.jpg', 'SB', 'MF', 'Arsenal', 480, 'A', 62, 11),
(308, 'Declan Rice', '308.jpg', 'SB', 'MF', 'Arsenal', 470, 'A', 62, 11),
(309, 'William Saliba', '309.jpg', 'SB', 'DF', 'Arsenal', 460, 'A', 62, 11),
(310, 'Aaron Ramsdale', '310.jpg', 'SB', 'GK', 'Arsenal', 450, 'A', 62, 11),

-- Team63 (TeamID=63)
(311, 'Nicolas Jackson', '311.jpg', 'SB', 'FW', 'Chelsea', 480, 'A', 63, 11),
(312, 'Enzo Fernández', '312.jpg', 'SB', 'MF', 'Chelsea', 470, 'A', 63, 11),
(313, 'Raheem Sterling', '313.jpg', 'SB', 'MF', 'Chelsea', 460, 'A', 63, 11),
(314, 'Thiago Silva', '314.jpg', 'SB', 'DF', 'Chelsea', 450, 'A', 63, 11),
(315, 'Kepa Arrizabalaga', '315.jpg', 'SB', 'GK', 'Chelsea', 440, 'A', 63, 11),

-- Team64 (TeamID=64)
(316, 'Victor Osimhen', '316.jpg', 'SB', 'FW', 'Napoli', 490, 'A', 64, 11),
(317, 'Khvicha Kvaratskhelia', '317.jpg', 'SB', 'MF', 'Napoli', 480, 'A', 64, 11),
(318, 'Piotr Zieliński', '318.jpg', 'SB', 'MF', 'Napoli', 470, 'A', 64, 11),
(319, 'Giovanni Di Lorenzo', '319.jpg', 'SB', 'DF', 'Napoli', 460, 'A', 64, 11),
(320, 'Alex Meret', '320.jpg', 'SB', 'GK', 'Napoli', 450, 'A', 64, 11),

-- Team65 (TeamID=65)
(321, 'Lautaro Martínez', '321.jpg', 'SB', 'FW', 'Inter Milan', 480, 'A', 65, 11),
(322, 'Nicolò Barella', '322.jpg', 'SB', 'MF', 'Inter Milan', 470, 'A', 65, 11),
(323, 'Hakan Çalhanoğlu', '323.jpg', 'SB', 'MF', 'Inter Milan', 460, 'A', 65, 11),
(324, 'Milan Škriniar', '324.jpg', 'SB', 'DF', 'Inter Milan', 450, 'A', 65, 11),
(325, 'André Onana', '325.jpg', 'SB', 'GK', 'Inter Milan', 440, 'A', 65, 11),

-- Team66 (TeamID=66)
(326, 'Dusan Vlahovic', '326.jpg', 'SB', 'FW', 'Juventus', 480, 'A', 66, 11),
(327, 'Paul Pogba', '327.jpg', 'SB', 'MF', 'Juventus', 470, 'A', 66, 11),
(328, 'Federico Chiesa', '328.jpg', 'SB', 'MF', 'Juventus', 460, 'A', 66, 11),
(329, 'Leonardo Bonucci', '329.jpg', 'SB', 'DF', 'Juventus', 450, 'A', 66, 11),
(330, 'Wojciech Szczęsny', '330.jpg', 'SB', 'GK', 'Juventus', 440, 'A', 66, 11),

-- LeagueID=12 (SB)，Team67 - Team72
-- Team67 (TeamID=67)
(331, 'Aaron Jenkins', '331.jpg', 'SB', 'FW', 'Al-Hilal', 490, 'A', 67, 12),
(332, 'Rúben Neves', '332.jpg', 'SB', 'MF', 'Al-Hilal', 480, 'A', 67, 12),
(333, 'Sergej Milinković-Savić', '333.jpg', 'SB', 'MF', 'Al-Hilal', 470, 'A', 67, 12),
(334, 'Khalifah Al-Dawsari', '334.jpg', 'SB', 'DF', 'Al-Hilal', 460, 'A', 67, 12),
(335, 'Carter Butler', '335.jpg', 'SB', 'GK', 'Al-Hilal', 450, 'A', 67, 12),

-- Team68 (TeamID=68)
(336, 'Stella Gray', '336.jpg', 'SB', 'FW', 'Al-Nassr', 500, 'A', 68, 12),
(337, 'Sophie Simmons', '337.jpg', 'SB', 'FW', 'Al-Nassr', 490, 'A', 68, 12),
(338, 'Bella Ramirez', '338.jpg', 'SB', 'MF', 'Al-Nassr', 480, 'A', 68, 12),
(339, 'Mason Brooks', '339.jpg', 'SB', 'MF', 'Al-Nassr', 470, 'A', 68, 12),
(340, 'Zoey Bryant', '340.jpg', 'SB', 'GK', 'Al-Nassr', 460, 'A', 68, 12),

-- Team69 (TeamID=69)
(341, 'Justin Diaz', '341.jpg', 'SB', 'FW', 'Al-Ittihad', 490, 'A', 69, 12),
(342, 'Violet Watson', '342.jpg', 'SB', 'MF', 'Al-Ittihad', 480, 'A', 69, 12),
(343, 'Gavin Russell', '343.jpg', 'SB', 'MF', 'Al-Ittihad', 470, 'A', 69, 12),
(344, 'Audrey Perry', '344.jpg', 'SB', 'DF', 'Al-Ittihad', 460, 'A', 69, 12),
(345, 'Elijah Powell', '345.jpg', 'SB', 'GK', 'Al-Ittihad', 450, 'A', 69, 12),

-- Team70 (TeamID=70)
(346, 'Sergio Ramos', '346.jpg', 'SB', 'DF', 'Sevilla FC', 470, 'A', 70, 12),
(347, 'Ivan Rakitić', '347.jpg', 'SB', 'MF', 'Sevilla FC', 460, 'A', 70, 12),
(348, 'Erik Lamela', '348.jpg', 'SB', 'MF', 'Sevilla FC', 450, 'A', 70, 12),
(349, 'Jesús Navas', '349.jpg', 'SB', 'DF', 'Sevilla FC', 440, 'A', 70, 12),
(350, 'Yassine Bounou', '350.jpg', 'SB', 'GK', 'Sevilla FC', 430, 'A', 70, 12),

-- Team71 (TeamID=71)
(351, 'Edinson Cavani', '351.jpg', 'SB', 'FW', 'Valencia CF', 470, 'A', 71, 12),
(352, 'André Almeida', '352.jpg', 'SB', 'MF', 'Valencia CF', 460, 'A', 71, 12),
(353, 'Hugo Guillamón', '353.jpg', 'SB', 'MF', 'Valencia CF', 450, 'A', 71, 12),
(354, 'José Gayà', '354.jpg', 'SB', 'DF', 'Valencia CF', 440, 'A', 71, 12),
(355, 'Giorgi Mamardashvili', '355.jpg', 'SB', 'GK', 'Valencia CF', 430, 'A', 71, 12),

-- Team72 (TeamID=72)
(356, 'Antoine Griezmann', '356.jpg', 'SB', 'FW', 'Atlético Madrid', 480, 'A', 72, 12),
(357, 'Marcos Llorente', '357.jpg', 'SB', 'MF', 'Atlético Madrid', 470, 'A', 72, 12),
(358, 'Koke', '358.jpg', 'SB', 'MF', 'Atlético Madrid', 460, 'A', 72, 12),
(359, 'José Giménez', '359.jpg', 'SB', 'DF', 'Atlético Madrid', 450, 'A', 72, 12),
(360, 'Jan Oblak', '360.jpg', 'SB', 'GK', 'Atlético Madrid', 440, 'A', 72, 12);


-- MatchDetail
INSERT INTO MatchDetail (MatchID, MatchDate, FinalScore, Winner)
VALUES
-- FTB 
(1, '2024-01-15', '28-21', 'Thunderbolts'),
(2, '2024-01-22', '14-7', 'Mighty Eagles'),
(3, '2024-01-29', '21-14', 'Golden Griffins'),

(4, '2024-02-05', '35-28', 'Fire Falcons'),
(5, '2024-02-12', '24-17', 'Blazing Suns'),
(6, '2024-02-19', '31-31', 'Draw'),

(7, '2024-03-01', '27-20', 'Frost Bears'),
(8, '2024-03-08', '14-14', 'Draw'),
(9, '2024-03-15', '17-10', 'Thunder Sharks'),

(10, '2024-03-22', '35-31', 'Lava Titans'),
(11, '2024-03-29', '28-24', 'Inferno Foxes'),
(12, '2024-04-05', '21-21', 'Draw'),

-- BB 
(13, '2024-04-12', '110-102', 'Golden Hoops'),
(14, '2024-04-19', '98-95', 'Flying Ballers'),
(15, '2024-04-26', '105-99', 'Basket Titans'),

(16, '2024-05-03', '112-110', 'Fast Dribblers'),
(17, '2024-05-10', '101-100', 'Pivot Panthers'),
(18, '2024-05-17', '95-92', 'Hoop Dreams'),

(19, '2024-05-24', '120-118', 'Dribble Wizards'),
(20, '2024-05-31', '102-98', 'Slam Dunkers'),
(21, '2024-06-07', '108-105', 'Fast Breakers'),

(22, '2024-06-14', '99-97', 'Triple Threat'),
(23, '2024-06-21', '115-110', 'Zone Defenders'),
(24, '2024-06-28', '100-99', 'Paint Protectors'),

-- SB 
(25, '2024-07-05', '2-1', 'Goal Scorers'),
(26, '2024-07-12', '1-0', 'Penalty Kings'),
(27, '2024-07-19', '3-2', 'Free Kick Masters'),

(28, '2024-07-26', '2-2', 'Draw'),
(29, '2024-08-02', '1-1', 'Draw'),
(30, '2024-08-09', '0-0', 'Draw'),

(31, '2024-08-16', '4-3', 'Pass Masters'),
(32, '2024-08-23', '2-1', 'Counter Attackers'),
(33, '2024-08-30', '1-0', 'Set Piece Specialists'),

(34, '2024-09-06', '3-1', 'Attacking Stars'),
(35, '2024-09-13', '2-0', 'Sweeper Keepers'),
(36, '2024-09-20', '1-1', 'Draw');


-- MatchTeam
INSERT INTO MatchTeam (MatchID, TeamID, HomeOrAway)
VALUES
-- FTB 
(1, 1, 'Home'), (1, 2, 'Away'),
(2, 3, 'Home'), (2, 4, 'Away'),
(3, 5, 'Home'), (3, 6, 'Away'),

(4, 7, 'Home'), (4, 8, 'Away'),
(5, 9, 'Home'), (5, 10, 'Away'),
(6, 11, 'Home'), (6, 12, 'Away'),

(7, 13, 'Home'), (7, 14, 'Away'),
(8, 15, 'Home'), (8, 16, 'Away'),
(9, 17, 'Home'), (9, 18, 'Away'),

(10, 19, 'Home'), (10, 20, 'Away'),
(11, 21, 'Home'), (11, 22, 'Away'),
(12, 23, 'Home'), (12, 24, 'Away'),

-- BB 
(13, 25, 'Home'), (13, 26, 'Away'),
(14, 27, 'Home'), (14, 28, 'Away'),
(15, 29, 'Home'), (15, 30, 'Away'),

(16, 31, 'Home'), (16, 32, 'Away'),
(17, 33, 'Home'), (17, 34, 'Away'),
(18, 35, 'Home'), (18, 36, 'Away'),

(19, 37, 'Home'), (19, 38, 'Away'),
(20, 39, 'Home'), (20, 40, 'Away'),
(21, 41, 'Home'), (21, 42, 'Away'),

(22, 43, 'Home'), (22, 44, 'Away'),
(23, 45, 'Home'), (23, 46, 'Away'),
(24, 47, 'Home'), (24, 48, 'Away'),

-- SB 
(25, 49, 'Home'), (25, 50, 'Away'),
(26, 51, 'Home'), (26, 52, 'Away'),
(27, 53, 'Home'), (27, 54, 'Away'),

(28, 55, 'Home'), (28, 56, 'Away'),
(29, 57, 'Home'), (29, 58, 'Away'),
(30, 59, 'Home'), (30, 60, 'Away'),

(31, 61, 'Home'), (31, 62, 'Away'),
(32, 63, 'Home'), (32, 64, 'Away'),
(33, 65, 'Home'), (33, 66, 'Away'),

(34, 67, 'Home'), (34, 68, 'Away'),
(35, 69, 'Home'), (35, 70, 'Away'),
(36, 71, 'Home'), (36, 72, 'Away');



-- PlayerStats
INSERT INTO PlayerStats (StatsID, PlayerID, GameDate, PerformanceStats, InjuryStatus)
VALUES
-- MatchID 1: Teams 1 (TeamID=1) vs 2 (TeamID=2) on 2024-01-15
(1, 1, '2024-01-15', 'Passed for 320 yards, 3 TDs', 'N'),    -- Team 1
(2, 2, '2024-01-15', 'Caught 120 yards, 2 TDs', 'N'),
(3, 3, '2024-01-15', 'Rushed for 85 yards, 1 TD', 'N'),
(4, 4, '2024-01-15', 'Caught 60 yards', 'N'),
(5, 5, '2024-01-15', 'Kicked 3 Field Goals', 'N'),
(6, 6, '2024-01-15', 'Passed for 300 yards, 2 TDs, 1 INT', 'N'),  -- Team 2
(7, 7, '2024-01-15', 'Caught 110 yards, 1 TD', 'N'),
(8, 8, '2024-01-15', 'Rushed for 75 yards', 'N'),
(9, 9, '2024-01-15', 'Caught 50 yards', 'N'),
(10, 10, '2024-01-15', 'Kicked 2 Field Goals', 'N'),

-- MatchID 2: Teams 3 (TeamID=3) vs 4 (TeamID=4) on 2024-01-22
(11, 11, '2024-01-22', 'Passed for 310 yards, 2 TDs', 'N'),   -- Team 3
(12, 12, '2024-01-22', 'Caught 130 yards, 1 TD', 'N'),
(13, 13, '2024-01-22', 'Rushed for 90 yards, 1 TD', 'N'),
(14, 14, '2024-01-22', 'Caught 60 yards', 'N'),
(15, 15, '2024-01-22', 'Kicked 1 Field Goal', 'N'),
(16, 16, '2024-01-22', 'Passed for 350 yards, 3 TDs', 'N'),   -- Team 4
(17, 17, '2024-01-22', 'Caught 125 yards, 2 TDs', 'N'),
(18, 18, '2024-01-22', 'Rushed for 80 yards', 'N'),
(19, 19, '2024-01-22', 'Caught 70 yards, 1 TD', 'N'),
(20, 20, '2024-01-22', 'Kicked 2 Field Goals', 'N'),

-- MatchID 3: Teams 5 (TeamID=5) vs 6 (TeamID=6) on 2024-01-29
(21, 21, '2024-01-29', 'Passed for 335 yards, 2 TDs', 'N'),   -- Team 5
(22, 22, '2024-01-29', 'Caught 105 yards, 1 TD', 'N'),
(23, 23, '2024-01-29', 'Rushed for 95 yards, 1 TD', 'N'),
(24, 24, '2024-01-29', 'Caught 50 yards', 'N'),
(25, 25, '2024-01-29', 'Kicked 3 Field Goals', 'N'),
(26, 26, '2024-01-29', 'Passed for 325 yards, 2 TDs', 'N'),   -- Team 6
(27, 27, '2024-01-29', 'Caught 115 yards, 1 TD', 'N'),
(28, 28, '2024-01-29', 'Rushed for 85 yards', 'N'),
(29, 29, '2024-01-29', 'Caught 60 yards', 'N'),
(30, 30, '2024-01-29', 'Kicked 2 Field Goals', 'N'),

-- MatchID 4: Teams 7 (TeamID=7) vs 8 (TeamID=8) on 2024-02-05
(31, 31, '2024-02-05', 'Passed for 310 yards, 3 TDs', 'N'),   -- Team 7
(32, 32, '2024-02-05', 'Caught 140 yards, 2 TDs', 'N'),
(33, 33, '2024-02-05', 'Rushed for 85 yards, 1 TD', 'N'),
(34, 34, '2024-02-05', 'Caught 70 yards', 'N'),
(35, 35, '2024-02-05', 'Kicked 2 Field Goals', 'N'),
(36, 36, '2024-02-05', 'Passed for 330 yards, 2 TDs', 'N'),   -- Team 8
(37, 37, '2024-02-05', 'Caught 120 yards, 1 TD', 'N'),
(38, 38, '2024-02-05', 'Rushed for 90 yards', 'N'),
(39, 39, '2024-02-05', 'Caught 65 yards', 'N'),
(40, 40, '2024-02-05', 'Kicked 3 Field Goals', 'N'),

-- MatchID 5: Teams 9 (TeamID=9) vs 10 (TeamID=10) on 2024-02-12
(41, 41, '2024-02-12', 'Passed for 315 yards, 2 TDs', 'N'),   -- Team 9
(42, 42, '2024-02-12', 'Caught 110 yards, 1 TD', 'N'),
(43, 43, '2024-02-12', 'Rushed for 80 yards', 'N'),
(44, 44, '2024-02-12', 'Caught 55 yards', 'N'),
(45, 45, '2024-02-12', 'Kicked 2 Field Goals', 'N'),
(46, 46, '2024-02-12', 'Passed for 340 yards, 3 TDs', 'N'),   -- Team 10
(47, 47, '2024-02-12', 'Caught 130 yards, 2 TDs', 'N'),
(48, 48, '2024-02-12', 'Rushed for 85 yards, 1 TD', 'N'),
(49, 49, '2024-02-12', 'Caught 75 yards', 'N'),
(50, 50, '2024-02-12', 'Kicked 3 Field Goals', 'N'),

-- MatchID 6: Teams 11 (TeamID=11) vs 12 (TeamID=12) on 2024-02-19
(51, 51, '2024-02-19', 'Passed for 310 yards, 2 TDs', 'N'),   -- Team 11
(52, 52, '2024-02-19', 'Caught 120 yards, 1 TD', 'N'),
(53, 53, '2024-02-19', 'Rushed for 90 yards', 'N'),
(54, 54, '2024-02-19', 'Caught 65 yards', 'N'),
(55, 55, '2024-02-19', 'Kicked 2 Field Goals', 'N'),
(56, 56, '2024-02-19', 'Passed for 325 yards, 3 TDs', 'N'),   -- Team 12
(57, 57, '2024-02-19', 'Caught 115 yards, 1 TD', 'N'),
(58, 58, '2024-02-19', 'Rushed for 80 yards', 'N'),
(59, 59, '2024-02-19', 'Caught 70 yards', 'N'),
(60, 60, '2024-02-19', 'Kicked 3 Field Goals', 'N'),

-- MatchID 7: Teams 13 (TeamID=13) vs 14 (TeamID=14) on 2024-03-01
(61, 61, '2024-03-01', 'Passed for 300 yards, 2 TDs', 'N'),   -- Team 13
(62, 62, '2024-03-01', 'Caught 115 yards, 1 TD', 'N'),
(63, 63, '2024-03-01', 'Rushed for 85 yards', 'N'),
(64, 64, '2024-03-01', 'Caught 60 yards', 'N'),
(65, 65, '2024-03-01', 'Kicked 2 Field Goals', 'N'),
(66, 66, '2024-03-01', 'Passed for 320 yards, 3 TDs', 'N'),   -- Team 14
(67, 67, '2024-03-01', 'Caught 125 yards, 2 TDs', 'N'),
(68, 68, '2024-03-01', 'Rushed for 80 yards', 'N'),
(69, 69, '2024-03-01', 'Caught 70 yards', 'N'),
(70, 70, '2024-03-01', 'Kicked 3 Field Goals', 'N'),

-- MatchID 8: Teams 15 (TeamID=15) vs 16 (TeamID=16) on 2024-03-08
(71, 71, '2024-03-08', 'Passed for 310 yards, 1 TD', 'N'),    -- Team 15
(72, 72, '2024-03-08', 'Caught 110 yards', 'Y'),              -- Injured
(73, 73, '2024-03-08', 'Rushed for 75 yards', 'N'),
(74, 74, '2024-03-08', 'Caught 60 yards', 'N'),
(75, 75, '2024-03-08', 'Kicked 1 Field Goal', 'N'),
(76, 76, '2024-03-08', 'Passed for 340 yards, 2 TDs', 'N'),   -- Team 16
(77, 77, '2024-03-08', 'Caught 120 yards, 1 TD', 'N'),
(78, 78, '2024-03-08', 'Rushed for 80 yards', 'N'),
(79, 79, '2024-03-08', 'Caught 65 yards', 'N'),
(80, 80, '2024-03-08', 'Kicked 2 Field Goals', 'N'),

-- MatchID 9: Teams 17 (TeamID=17) vs 18 (TeamID=18) on 2024-03-15
(81, 81, '2024-03-15', 'Passed for 295 yards, 2 TDs', 'N'),   -- Team 17
(82, 82, '2024-03-15', 'Caught 105 yards, 1 TD', 'N'),
(83, 83, '2024-03-15', 'Rushed for 90 yards', 'N'),
(84, 84, '2024-03-15', 'Caught 50 yards', 'N'),
(85, 85, '2024-03-15', 'Kicked 1 Field Goal', 'N'),
(86, 86, '2024-03-15', 'Passed for 280 yards, 1 TD', 'N'),    -- Team 18
(87, 87, '2024-03-15', 'Caught 95 yards', 'N'),
(88, 88, '2024-03-15', 'Rushed for 85 yards', 'N'),
(89, 89, '2024-03-15', 'Caught 55 yards', 'N'),
(90, 90, '2024-03-15', 'Kicked 2 Field Goals', 'N'),

-- MatchID 10: Teams 19 (TeamID=19) vs 20 (TeamID=20) on 2024-03-22
(91, 91, '2024-03-22', 'Passed for 330 yards, 3 TDs', 'N'),   -- Team 19
(92, 92, '2024-03-22', 'Caught 140 yards, 2 TDs', 'N'),
(93, 93, '2024-03-22', 'Rushed for 95 yards, 1 TD', 'N'),
(94, 94, '2024-03-22', 'Caught 70 yards', 'N'),
(95, 95, '2024-03-22', 'Kicked 2 Field Goals', 'N'),
(96, 96, '2024-03-22', 'Passed for 315 yards, 2 TDs', 'N'),   -- Team 20
(97, 97, '2024-03-22', 'Caught 115 yards, 1 TD', 'N'),
(98, 98, '2024-03-22', 'Rushed for 85 yards', 'N'),
(99, 99, '2024-03-22', 'Caught 60 yards', 'N'),
(100, 100, '2024-03-22', 'Kicked 3 Field Goals', 'N'),

-- MatchID 11: Teams 21 (TeamID=21) vs 22 (TeamID=22) on 2024-03-29
(101, 101, '2024-03-29', 'Passed for 310 yards, 2 TDs', 'N'),  -- Team 21
(102, 102, '2024-03-29', 'Caught 120 yards, 1 TD', 'N'),
(103, 103, '2024-03-29', 'Rushed for 90 yards', 'N'),
(104, 104, '2024-03-29', 'Caught 65 yards', 'N'),
(105, 105, '2024-03-29', 'Kicked 2 Field Goals', 'N'),
(106, 106, '2024-03-29', 'Passed for 325 yards, 3 TDs', 'N'),  -- Team 22
(107, 107, '2024-03-29', 'Caught 115 yards, 1 TD', 'N'),
(108, 108, '2024-03-29', 'Rushed for 80 yards', 'N'),
(109, 109, '2024-03-29', 'Caught 70 yards', 'N'),
(110, 110, '2024-03-29', 'Kicked 3 Field Goals', 'N'),

-- MatchID 12: Teams 23 (TeamID=23) vs 24 (TeamID=24) on 2024-04-05
(111, 111, '2024-04-05', 'Passed for 300 yards, 2 TDs', 'N'),  -- Team 23
(112, 112, '2024-04-05', 'Caught 115 yards, 1 TD', 'N'),
(113, 113, '2024-04-05', 'Rushed for 85 yards', 'N'),
(114, 114, '2024-04-05', 'Caught 60 yards', 'N'),
(115, 115, '2024-04-05', 'Kicked 2 Field Goals', 'N'),
(116, 116, '2024-04-05', 'Passed for 320 yards, 3 TDs', 'N'),  -- Team 24
(117, 117, '2024-04-05', 'Caught 125 yards, 2 TDs', 'N'),
(118, 118, '2024-04-05', 'Rushed for 80 yards', 'N'),
(119, 119, '2024-04-05', 'Caught 70 yards', 'N'),
(120, 120, '2024-04-05', 'Kicked 3 Field Goals', 'N'),

-- Team 25 Players
(121, 121, '2024-04-12', 'Scored 28 points, 8 rebounds, 7 assists', 'N'),   -- LeBron James
(122, 122, '2024-04-12', 'Scored 24 points, 10 rebounds, 2 blocks', 'N'),   -- Anthony Davis
(123, 123, '2024-04-12', 'Scored 15 points, 7 assists, 5 rebounds', 'N'),   -- Russell Westbrook
(124, 124, '2024-04-12', 'Scored 12 points, 5 rebounds', 'N'),              -- Austin Reaves
(125, 125, '2024-04-12', 'Scored 8 points, 6 rebounds', 'N'),               -- Dwight Howard

-- Team 26 Players
(126, 126, '2024-04-12', 'Scored 32 points, 9 assists, 5 rebounds', 'N'),   -- Stephen Curry
(127, 127, '2024-04-12', 'Scored 25 points, 4 rebounds, 3 assists', 'N'),   -- Klay Thompson
(128, 128, '2024-04-12', 'Scored 10 points, 8 rebounds, 7 assists', 'N'),   -- Draymond Green
(129, 129, '2024-04-12', 'Scored 18 points, 6 rebounds', 'N'),              -- Andrew Wiggins
(130, 130, '2024-04-12', 'Scored 6 points, 10 rebounds', 'N'),              -- Kevon Looney

-- MatchID 14: Teams 27 vs 28 on 2024-04-19
-- Team 27 Players
(131, 131, '2024-04-19', 'Scored 30 points, 7 rebounds, 5 assists', 'N'),   -- Kevin Durant
(132, 132, '2024-04-19', 'Scored 28 points, 6 assists', 'N'),               -- Devin Booker
(133, 133, '2024-04-19', 'Scored 12 points, 10 assists', 'N'),              -- Chris Paul
(134, 134, '2024-04-19', 'Scored 15 points, 9 rebounds', 'N'),              -- Deandre Ayton
(135, 135, '2024-04-19', 'Scored 10 points, 4 rebounds', 'N'),              -- Mikal Bridges

-- Team 28 Players
(136, 136, '2024-04-19', 'Scored 35 points, 12 rebounds, 5 assists', 'N'),  -- Giannis Antetokounmpo
(137, 137, '2024-04-19', 'Scored 20 points, 5 rebounds, 4 assists', 'N'),   -- Khris Middleton
(138, 138, '2024-04-19', 'Scored 18 points, 7 assists', 'N'),               -- Jrue Holiday
(139, 139, '2024-04-19', 'Scored 10 points, 8 rebounds', 'N'),              -- Brook Lopez
(140, 140, '2024-04-19', 'Scored 12 points, 6 rebounds', 'N'),              -- Bobby Portis

-- MatchID 15: Teams 29 vs 30 on 2024-04-26
-- Team 29 Players
(141, 141, '2024-04-26', 'Scored 38 points, 9 rebounds, 8 assists', 'N'),   -- Luka Doncic
(142, 142, '2024-04-26', 'Scored 27 points, 7 assists', 'N'),               -- Kyrie Irving
(143, 143, '2024-04-26', 'Scored 15 points, 4 rebounds', 'N'),              -- Tim Hardaway Jr.
(144, 144, '2024-04-26', 'Scored 10 points, 8 rebounds', 'N'),              -- Christian Wood
(145, 145, '2024-04-26', 'Scored 6 points, 5 rebounds', 'N'),               -- Dorian Finney-Smith

-- Team 30 Players
(146, 146, '2024-04-26', 'Scored 34 points, 10 rebounds, 5 assists', 'N'),  -- Jayson Tatum
(147, 147, '2024-04-26', 'Scored 29 points, 6 rebounds', 'N'),              -- Jaylen Brown
(148, 148, '2024-04-26', 'Scored 12 points, 8 assists', 'N'),               -- Marcus Smart
(149, 149, '2024-04-26', 'Scored 8 points, 6 rebounds', 'N'),               -- Al Horford
(150, 150, '2024-04-26', 'Scored 10 points, 7 rebounds', 'N'),              -- Robert Williams III

-- MatchID 16: Teams 31 vs 32 on 2024-05-03
-- Team 31 Players
(151, 151, '2024-05-03', 'Scored 36 points, 12 rebounds, 4 blocks', 'N'),   -- Joel Embiid
(152, 152, '2024-05-03', 'Scored 22 points, 10 assists', 'N'),              -- James Harden
(153, 153, '2024-05-03', 'Scored 18 points, 5 assists', 'N'),               -- Tyrese Maxey
(154, 154, '2024-05-03', 'Scored 15 points, 7 rebounds', 'N'),              -- Tobias Harris
(155, 155, '2024-05-03', 'Scored 8 points, 6 rebounds', 'N'),               -- PJ Tucker

-- Team 32 Players
(156, 156, '2024-05-03', 'Scored 33 points, 9 assists, 7 rebounds', 'N'),   -- Ja Morant
(157, 157, '2024-05-03', 'Scored 20 points, 10 rebounds', 'N'),             -- Jaren Jackson Jr.
(158, 158, '2024-05-03', 'Scored 18 points, 6 rebounds', 'N'),              -- Desmond Bane
(159, 159, '2024-05-03', 'Scored 12 points, 5 rebounds', 'N'),              -- Dillon Brooks
(160, 160, '2024-05-03', 'Scored 8 points, 10 rebounds', 'N'),              -- Steven Adams

-- MatchID 17: Teams 33 vs 34 on 2024-05-10
-- Team 33 Players
(161, 161, '2024-05-10', 'Scored 30 points, 6 assists', 'N'),               -- Donovan Mitchell
(162, 162, '2024-05-10', 'Scored 25 points, 7 assists', 'N'),               -- Darius Garland
(163, 163, '2024-05-10', 'Scored 15 points, 10 rebounds', 'N'),             -- Evan Mobley
(164, 164, '2024-05-10', 'Scored 12 points, 9 rebounds', 'N'),              -- Jarrett Allen
(165, 165, '2024-05-10', 'Scored 10 points, 4 assists', 'N'),               -- Caris LeVert

-- Team 34 Players
(166, 166, '2024-05-10', 'Scored 28 points, 5 rebounds', 'N'),              -- DeMar DeRozan
(167, 167, '2024-05-10', 'Scored 26 points, 6 assists', 'N'),               -- Zach LaVine
(168, 168, '2024-05-10', 'Scored 18 points, 10 rebounds', 'N'),             -- Nikola Vucevic
(169, 169, '2024-05-10', 'Did not play (Injury)', 'Y'),                     -- Lonzo Ball
(170, 170, '2024-05-10', 'Scored 8 points, 5 rebounds', 'N'), 

-- MatchID 18: Teams 35 (TeamID=35) vs 36 (TeamID=36) on 2024-05-17
-- Team 35 Players
(171, 171, '2024-05-17', 'Scored 33 points, 11 assists, 4 rebounds', 'N'),  -- Trae Young
(172, 172, '2024-05-17', 'Scored 24 points, 7 rebounds, 5 assists', 'N'),   -- Dejounte Murray
(173, 173, '2024-05-17', 'Scored 18 points, 9 rebounds', 'N'),              -- John Collins
(174, 174, '2024-05-17', 'Scored 12 points, 14 rebounds, 2 blocks', 'N'),   -- Clint Capela
(175, 175, '2024-05-17', 'Scored 15 points, 3 rebounds', 'N'),              -- Bogdan Bogdanovic

-- Team 36 Players
(176, 176, '2024-05-17', 'Scored 40 points, 8 assists, 5 rebounds', 'N'),   -- Damian Lillard
(177, 177, '2024-05-17', 'Scored 22 points, 5 assists', 'N'),               -- Anfernee Simons
(178, 178, '2024-05-17', 'Scored 18 points, 7 rebounds', 'N'),              -- Jerami Grant
(179, 179, '2024-05-17', 'Scored 14 points, 12 rebounds', 'N'),             -- Jusuf Nurkic
(180, 180, '2024-05-17', 'Scored 10 points, 6 rebounds', 'N'),              -- Josh Hart

-- MatchID 19: Teams 37 (TeamID=37) vs 38 (TeamID=38) on 2024-05-24
-- Team 37 Players
(181, 181, '2024-05-24', 'Scored 28 points, 7 rebounds, 5 assists', 'N'),   -- Jimmy Butler
(182, 182, '2024-05-24', 'Scored 20 points, 10 rebounds, 3 assists', 'N'),  -- Bam Adebayo
(183, 183, '2024-05-24', 'Scored 22 points, 4 rebounds, 6 assists', 'N'),   -- Tyler Herro
(184, 184, '2024-05-24', 'Scored 10 points, 8 assists', 'N'),               -- Kyle Lowry
(185, 185, '2024-05-24', 'Scored 12 points, 3 rebounds', 'N'),              -- Victor Oladipo

-- Team 38 Players
(186, 186, '2024-05-24', 'Scored 15 points, 12 assists, 4 rebounds', 'N'),  -- Chris Paul
(187, 187, '2024-05-24', 'Scored 35 points, 6 rebounds, 4 assists', 'N'),   -- Devin Booker
(188, 188, '2024-05-24', 'Scored 18 points, 11 rebounds', 'N'),             -- Deandre Ayton
(189, 189, '2024-05-24', 'Scored 14 points, 5 rebounds', 'N'),              -- Mikal Bridges
(190, 190, '2024-05-24', 'Scored 10 points, 4 rebounds', 'N'),              -- Cameron Johnson

-- MatchID 20: Teams 39 (TeamID=39) vs 40 (TeamID=40) on 2024-05-31
-- Team 39 Players
(191, 191, '2024-05-31', 'Scored 25 points, 10 rebounds, 4 assists', 'N'),  -- Karl-Anthony Towns
(192, 192, '2024-05-31', 'Scored 30 points, 5 rebounds, 3 assists', 'N'),   -- Anthony Edwards
(193, 193, '2024-05-31', 'Scored 12 points, 14 rebounds, 3 blocks', 'N'),   -- Rudy Gobert
(194, 194, '2024-05-31', 'Scored 18 points, 7 assists', 'N'),               -- D'Angelo Russell
(195, 195, '2024-05-31', 'Scored 10 points, 5 rebounds', 'N'),              -- Jaden McDaniels

-- Team 40 Players
(196, 196, '2024-05-31', 'Scored 28 points, 6 rebounds, 5 assists', 'N'),   -- Paul George
(197, 197, '2024-05-31', 'Scored 30 points, 8 rebounds, 4 assists', 'N'),   -- Kawhi Leonard
(198, 198, '2024-05-31', 'Scored 12 points, 5 assists', 'N'),               -- John Wall
(199, 199, '2024-05-31', 'Scored 14 points, 4 assists', 'N'),               -- Reggie Jackson
(200, 200, '2024-05-31', 'Scored 8 points, 10 rebounds', 'N'),              -- Ivica Zubac

-- MatchID 21: Teams 41 (TeamID=41) vs 42 (TeamID=42) on 2024-06-07
-- Team 41 Players
(201, 201, '2024-06-07', 'Scored 27 points, 5 rebounds, 4 assists', 'N'),   -- DeMar DeRozan
(202, 202, '2024-06-07', 'Scored 26 points, 6 rebounds, 5 assists', 'N'),   -- Zach LaVine
(203, 203, '2024-06-07', 'Scored 18 points, 12 rebounds', 'N'),             -- Nikola Vucevic
(204, 204, '2024-06-07', 'Did not play (Injury)', 'Y'),                     -- Lonzo Ball
(205, 205, '2024-06-07', 'Scored 10 points, 6 rebounds', 'N'),              -- Patrick Williams

-- Team 42 Players
(206, 206, '2024-06-07', 'Scored 32 points, 5 assists', 'N'),               -- Donovan Mitchell
(207, 207, '2024-06-07', 'Scored 24 points, 7 assists', 'N'),               -- Darius Garland
(208, 208, '2024-06-07', 'Scored 16 points, 10 rebounds', 'N'),             -- Evan Mobley
(209, 209, '2024-06-07', 'Scored 12 points, 9 rebounds', 'N'),              -- Jarrett Allen
(210, 210, '2024-06-07', 'Scored 14 points, 4 assists', 'N'),               -- Caris LeVert

-- MatchID 22: Teams 43 (TeamID=43) vs 44 (TeamID=44) on 2024-06-14
-- Team 43 Players
(211, 211, '2024-06-14', 'Scored 26 points, 6 rebounds, 5 assists', 'N'),   -- Brandon Ingram
(212, 212, '2024-06-14', 'Scored 28 points, 8 rebounds, 3 assists', 'N'),   -- Zion Williamson
(213, 213, '2024-06-14', 'Scored 22 points, 7 assists', 'N'),               -- CJ McCollum
(214, 214, '2024-06-14', 'Scored 14 points, 12 rebounds', 'N'),             -- Jonas Valanciunas
(215, 215, '2024-06-14', 'Scored 10 points, 5 rebounds', 'N'),              -- Herbert Jones

-- Team 44 Players
(216, 216, '2024-06-14', 'Scored 30 points, 5 rebounds, 6 assists', 'N'),   -- Bradley Beal
(217, 217, '2024-06-14', 'Scored 22 points, 9 rebounds', 'N'),              -- Kristaps Porzingis
(218, 218, '2024-06-14', 'Scored 18 points, 7 rebounds', 'N'),              -- Kyle Kuzma
(219, 219, '2024-06-14', 'Scored 8 points, 6 rebounds', 'N'),               -- Daniel Gafford
(220, 220, '2024-06-14', 'Scored 10 points, 5 assists', 'N'),               -- Monte Morris

-- MatchID 23: Teams 45 (TeamID=45) vs 46 (TeamID=46) on 2024-06-21
-- Team 45 Players
(221, 221, '2024-06-21', 'Scored 36 points, 7 assists', 'N'),               -- Damian Lillard
(222, 222, '2024-06-21', 'Scored 20 points, 5 assists', 'N'),               -- Anfernee Simons
(223, 223, '2024-06-21', 'Scored 16 points, 6 rebounds', 'N'),              -- Jerami Grant
(224, 224, '2024-06-21', 'Scored 12 points, 10 rebounds', 'N'),             -- Jusuf Nurkic
(225, 225, '2024-06-21', 'Scored 10 points, 5 rebounds', 'N'),              -- Josh Hart

-- Team 46 Players
(226, 226, '2024-06-21', 'Scored 28 points, 8 rebounds, 6 assists', 'N'),   -- Jimmy Butler
(227, 227, '2024-06-21', 'Scored 22 points, 12 rebounds', 'N'),             -- Bam Adebayo
(228, 228, '2024-06-21', 'Scored 18 points, 4 rebounds', 'N'),              -- Tyler Herro
(229, 229, '2024-06-21', 'Scored 10 points, 7 assists', 'N'),               -- Kyle Lowry
(230, 230, '2024-06-21', 'Scored 12 points, 3 rebounds', 'N'),              -- Victor Oladipo

-- MatchID 24: Teams 47 (TeamID=47) vs 48 (TeamID=48) on 2024-06-28
-- Team 47 Players
(231, 231, '2024-06-28', 'Scored 26 points, 5 rebounds, 4 assists', 'N'),   -- DeMar DeRozan
(232, 232, '2024-06-28', 'Scored 25 points, 6 rebounds, 5 assists', 'N'),   -- Zach LaVine
(233, 233, '2024-06-28', 'Scored 17 points, 11 rebounds', 'N'),             -- Nikola Vucevic
(234, 234, '2024-06-28', 'Did not play (Injury)', 'Y'),                     -- Lonzo Ball
(235, 235, '2024-06-28', 'Scored 11 points, 6 rebounds', 'N'),              -- Patrick Williams

-- Team 48 Players
(236, 236, '2024-06-28', 'Scored 31 points, 5 assists', 'N'),               -- Donovan Mitchell
(237, 237, '2024-06-28', 'Scored 23 points, 7 assists', 'N'),               -- Darius Garland
(238, 238, '2024-06-28', 'Scored 15 points, 9 rebounds', 'N'),              -- Evan Mobley
(239, 239, '2024-06-28', 'Scored 13 points, 8 rebounds', 'N'),              -- Jarrett Allen
(240, 240, '2024-06-28', 'Scored 12 points, 4 assists', 'N'),               -- Caris LeVert

-- Team 49 Players
(241, 241, '2024-07-05', 'Scored 2 goals, 1 assist', 'N'),    -- Lionel Messi
(242, 242, '2024-07-05', 'Controlled midfield, 90% pass accuracy', 'N'), -- Sergio Busquets
(243, 243, '2024-07-05', 'Provided defensive stability', 'N'), -- Jordi Alba
(244, 244, '2024-07-05', 'Scored 1 goal', 'N'),               -- Josef Martinez
(245, 245, '2024-07-05', 'Made 5 saves', 'N'),                -- Drake Callender

-- Team 50 Players
(246, 246, '2024-07-05', 'Scored 1 goal', 'N'),               -- Cristiano Ronaldo
(247, 247, '2024-07-05', 'Assisted 1 goal', 'N'),             -- Sadio Mane
(248, 248, '2024-07-05', 'Key passes and playmaking', 'N'),    -- Anderson Talisca
(249, 249, '2024-07-05', 'Strong defensive midfield play', 'N'), -- Luiz Gustavo
(250, 250, '2024-07-05', 'Made 4 saves', 'N'),                -- David Ospina

-- Team 51 Players (Paris Saint-Germain)
(251, 251, '2024-07-12', 'Scored 1 goal, 1 assist', 'N'),       -- Kylian Mbappe
(252, 252, '2024-07-12', 'Assisted 1 goal, created chances', 'N'), -- Neymar Jr
(253, 253, '2024-07-12', 'Controlled midfield, 90% pass accuracy', 'N'), -- Marco Verratti
(254, 254, '2024-07-12', 'Solid defense, 5 clearances', 'N'),   -- Marquinhos
(255, 255, '2024-07-12', 'Made 3 saves, clean sheet', 'N'),     -- Gianluigi Donnarumma

-- Team 52 Players (FC Barcelona)
(256, 256, '2024-07-12', 'Scored 1 goal', 'N'),                 -- Robert Lewandowski
(257, 257, '2024-07-12', 'Controlled midfield, key passes', 'N'), -- Pedri
(258, 258, '2024-07-12', 'Strong midfield presence', 'N'),      -- Frenkie de Jong
(259, 259, '2024-07-12', 'Solid defense, 4 tackles', 'N'),      -- Jules Kounde
(260, 260, '2024-07-12', 'Made 4 saves', 'N'),                  -- Marc-André ter Stegen

-- MatchID 27: Teams 53 (TeamID=53) vs 54 (TeamID=54) on 2024-07-19
-- Team 53 Players (Manchester City)
(261, 261, '2024-07-19', 'Scored 2 goals', 'N'),                -- Erling Haaland
(262, 262, '2024-07-19', 'Provided 2 assists', 'N'),            -- Kevin De Bruyne
(263, 263, '2024-07-19', 'Scored 1 goal', 'N'),                 -- Phil Foden
(264, 264, '2024-07-19', 'Solid defense, 3 interceptions', 'N'), -- Rúben Dias
(265, 265, '2024-07-19', 'Made 3 saves', 'N'),                  -- Ederson Moraes

-- Team 54 Players (Al-Ittihad)
(266, 266, '2024-07-19', 'Scored 1 goal, 1 assist', 'N'),       -- Karim Benzema
(267, 267, '2024-07-19', 'Dominated midfield, 85% pass accuracy', 'N'), -- N'Golo Kanté
(268, 268, '2024-07-19', 'Strong defensive midfield play', 'N'), -- Fabinho
(269, 269, '2024-07-19', 'Solid defense, 5 clearances', 'N'),   -- Ahmed Hegazi
(270, 270, '2024-07-19', 'Made 4 saves', 'N'),                  -- Marcelo Grohe

-- MatchID 28: Teams 55 (TeamID=55) vs 56 (TeamID=56) on 2024-07-26
-- Team 55 Players (Liverpool)
(271, 271, '2024-07-26', 'Scored 1 goal', 'N'),                 -- Mohamed Salah
(272, 272, '2024-07-26', 'Assisted 1 goal', 'N'),               -- Luis Díaz
(273, 273, '2024-07-26', 'Controlled midfield, 85% pass accuracy', 'N'), -- Jordan Henderson
(274, 274, '2024-07-26', 'Strong defense, 4 interceptions', 'N'), -- Virgil van Dijk
(275, 275, '2024-07-26', 'Made 3 saves', 'N'),                  -- Alisson Becker

-- Team 56 Players (Bayern Munich)
(276, 276, '2024-07-26', 'Scored 1 goal', 'N'),                 -- Harry Kane
(277, 277, '2024-07-26', 'Assisted 1 goal', 'N'),               -- Thomas Müller
(278, 278, '2024-07-26', 'Key passes, created chances', 'N'),   -- Jamal Musiala
(279, 279, '2024-07-26', 'Solid defense, 3 tackles', 'N'),      -- Joshua Kimmich
(280, 280, '2024-07-26', 'Made 4 saves', 'N'),                  -- Manuel Neuer

-- MatchID 29: Teams 57 (TeamID=57) vs 58 (TeamID=58) on 2024-08-02
-- Team 57 Players (Real Madrid)
(281, 281, '2024-08-02', 'Scored 1 goal, 1 assist', 'N'),       -- Vinícius Júnior
(282, 282, '2024-08-02', 'Assisted 1 goal, controlled midfield', 'N'), -- Luka Modrić
(283, 283, '2024-08-02', 'Key passes, 88% pass accuracy', 'N'), -- Toni Kroos
(284, 284, '2024-08-02', 'Solid defense, 4 clearances', 'N'),   -- David Alaba
(285, 285, '2024-08-02', 'Made 3 saves', 'N'),                  -- Thibaut Courtois

-- Team 58 Players (Manchester United)
(286, 286, '2024-08-02', 'Scored 1 goal', 'N'),                 -- Marcus Rashford
(287, 287, '2024-08-02', 'Assisted 1 goal', 'N'),               -- Bruno Fernandes
(288, 288, '2024-08-02', 'Strong defensive midfield play', 'N'), -- Casemiro
(289, 289, '2024-08-02', 'Solid defense, 3 tackles', 'N'),      -- Raphaël Varane
(290, 290, '2024-08-02', 'Made 4 saves', 'N'),                  -- David de Gea

-- MatchID 30: Teams 59 (TeamID=59) vs 60 (TeamID=60) on 2024-08-09
-- Team 59 Players (Al-Hilal)
(291, 291, '2024-08-09', 'Scored 1 goal', 'N'),                 -- André Carrillo
(292, 292, '2024-08-09', 'Assisted 1 goal', 'N'),               -- Matheus Pereira
(293, 293, '2024-08-09', 'Dominated midfield', 'N'),            -- Salman Al-Faraj
(294, 294, '2024-08-09', 'Strong defense, 4 clearances', 'N'),  -- Jang Hyun-soo
(295, 295, '2024-08-09', 'Made 3 saves', 'N'),                  -- Abdullah Al-Mayouf

-- Team 60 Players (Al-Ittihad)
(296, 296, '2024-08-09', 'Scored 1 goal', 'N'),                 -- Karim Benzema
(297, 297, '2024-08-09', 'Dominated midfield', 'N'),            -- N'Golo Kanté
(298, 298, '2024-08-09', 'Strong defensive midfield play', 'N'), -- Fabinho
(299, 299, '2024-08-09', 'Solid defense, 5 clearances', 'N'),   -- Ahmed Hegazi
(300, 300, '2024-08-09', 'Made 4 saves', 'N'),                  -- Marcelo Grohe

-- MatchID 31: Teams 61 (TeamID=61) vs 62 (TeamID=62) on 2024-08-16
-- Team 61 Players (Tottenham Hotspur)
(301, 301, '2024-08-16', 'Scored 2 goals', 'N'),                -- Heung-Min Son
(302, 302, '2024-08-16', 'Provided 1 assist', 'N'),             -- James Maddison
(303, 303, '2024-08-16', 'Controlled midfield', 'N'),           -- Pierre-Emile Højbjerg
(304, 304, '2024-08-16', 'Strong defense, 3 tackles', 'N'),     -- Cristian Romero
(305, 305, '2024-08-16', 'Made 5 saves', 'N'),                  -- Guglielmo Vicario

-- Team 62 Players (Arsenal)
(306, 306, '2024-08-16', 'Scored 1 goal', 'N'),                 -- Bukayo Saka
(307, 307, '2024-08-16', 'Assisted 1 goal', 'N'),               -- Martin Ødegaard
(308, 308, '2024-08-16', 'Dominated midfield', 'N'),            -- Declan Rice
(309, 309, '2024-08-16', 'Solid defense, 4 clearances', 'N'),   -- William Saliba
(310, 310, '2024-08-16', 'Made 3 saves', 'N'),                  -- Aaron Ramsdale

-- MatchID 32: Teams 63 (TeamID=63) vs 64 (TeamID=64) on 2024-08-23
-- Team 63 Players (Chelsea)
(311, 311, '2024-08-23', 'Scored 1 goal', 'N'),                 -- Nicolas Jackson
(312, 312, '2024-08-23', 'Assisted 1 goal', 'N'),               -- Enzo Fernández
(313, 313, '2024-08-23', 'Created key chances', 'N'),           -- Raheem Sterling
(314, 314, '2024-08-23', 'Strong defense, 3 tackles', 'N'),     -- Thiago Silva
(315, 315, '2024-08-23', 'Made 4 saves', 'N'),                  -- Kepa Arrizabalaga

-- Team 64 Players (Napoli)
(316, 316, '2024-08-23', 'Scored 1 goal', 'N'),                 -- Victor Osimhen
(317, 317, '2024-08-23', 'Assisted 1 goal', 'N'),               -- Khvicha Kvaratskhelia
(318, 318, '2024-08-23', 'Controlled midfield', 'N'),           -- Piotr Zieliński
(319, 319, '2024-08-23', 'Solid defense, 4 clearances', 'N'),   -- Giovanni Di Lorenzo
(320, 320, '2024-08-23', 'Made 3 saves', 'N'),                  -- Alex Meret

-- MatchID 33: Teams 65 (TeamID=65) vs 66 (TeamID=66) on 2024-08-30
-- Team 65 Players (Inter Milan)
(321, 321, '2024-08-30', 'Scored 2 goals', 'N'),                -- Lautaro Martínez
(322, 322, '2024-08-30', 'Provided 1 assist', 'N'),             -- Nicolò Barella
(323, 323, '2024-08-30', 'Dominated midfield', 'N'),            -- Hakan Çalhanoğlu
(324, 324, '2024-08-30', 'Strong defense, 4 tackles', 'N'),     -- Milan Škriniar
(325, 325, '2024-08-30', 'Made 5 saves', 'N'),                  -- André Onana

-- Team 66 Players (Juventus)
(326, 326, '2024-08-30', 'Scored 1 goal', 'N'),                 -- Dusan Vlahovic
(327, 327, '2024-08-30', 'Assisted 1 goal', 'N'),               -- Paul Pogba
(328, 328, '2024-08-30', 'Key passes, created chances', 'N'),   -- Federico Chiesa
(329, 329, '2024-08-30', 'Solid defense, 3 clearances', 'N'),   -- Leonardo Bonucci
(330, 330, '2024-08-30', 'Made 4 saves', 'N'),                  -- Wojciech Szczęsny

-- MatchID 34: Teams 67 (TeamID=67) vs 68 (TeamID=68) on 2024-09-06
-- Team 67 Players (Al-Hilal)
(331, 331, '2024-09-06', 'Scored 2 goals', 'N'),                -- Neymar Jr
(332, 332, '2024-09-06', 'Provided 1 assist', 'N'),             -- Rúben Neves
(333, 333, '2024-09-06', 'Dominated midfield', 'N'),            -- Sergej Milinković-Savić
(334, 334, '2024-09-06', 'Strong defense, 4 tackles', 'N'),     -- Khalifah Al-Dawsari
(335, 335, '2024-09-06', 'Made 5 saves', 'N'),                  -- Abdullah Al-Mayouf

-- Team 68 Players (Al-Nassr)
(336, 336, '2024-09-06', 'Scored 1 goal', 'N'),                 -- Cristiano Ronaldo
(337, 337, '2024-09-06', 'Assisted 1 goal', 'N'),               -- Sadio Mané
(338, 338, '2024-09-06', 'Created key chances', 'N'),           -- Anderson Talisca
(339, 339, '2024-09-06', 'Strong defensive midfield play', 'N'), -- Luiz Gustavo
(340, 340, '2024-09-06', 'Made 4 saves', 'N'),                  -- David Ospina

-- MatchID 35: Teams 69 (TeamID=69) vs 70 (TeamID=70) on 2024-09-13
-- Team 69 Players (Al-Ittihad)
(341, 341, '2024-09-13', 'Scored 1 goal', 'N'),                 -- Karim Benzema
(342, 342, '2024-09-13', 'Dominated midfield', 'N'),            -- N'Golo Kanté
(343, 343, '2024-09-13', 'Strong defensive midfield play', 'N'), -- Fabinho
(344, 344, '2024-09-13', 'Solid defense, 5 clearances', 'N'),   -- Ahmed Hegazi
(345, 345, '2024-09-13', 'Made 4 saves', 'N'),                  -- Marcelo Grohe

-- Team 70 Players (Sevilla FC)
(346, 346, '2024-09-13', 'Scored 1 goal', 'N'),                 -- Sergio Ramos
(347, 347, '2024-09-13', 'Assisted 1 goal', 'N'),               -- Ivan Rakitić
(348, 348, '2024-09-13', 'Created key chances', 'N'),           -- Erik Lamela
(349, 349, '2024-09-13', 'Solid defense, 4 clearances', 'N'),   -- Jesús Navas
(350, 350, '2024-09-13', 'Made 5 saves', 'N'),                  -- Yassine Bounou

-- MatchID 36: Teams 71 (TeamID=71) vs 72 (TeamID=72) on 2024-09-20
-- Team 71 Players (Valencia CF)
(351, 351, '2024-09-20', 'Scored 1 goal', 'N'),                 -- Edinson Cavani
(352, 352, '2024-09-20', 'Assisted 1 goal', 'N'),               -- André Almeida
(353, 353, '2024-09-20', 'Dominated midfield', 'N'),            -- Hugo Guillamón
(354, 354, '2024-09-20', 'Solid defense, 3 tackles', 'N'),      -- José Gayà
(355, 355, '2024-09-20', 'Made 4 saves', 'N'),                  -- Giorgi Mamardashvili

-- Team 72 Players (Atlético Madrid)
(356, 356, '2024-09-20', 'Scored 1 goal', 'N'),                 -- Antoine Griezmann
(357, 357, '2024-09-20', 'Assisted 1 goal', 'N'),               -- Marcos Llorente
(358, 358, '2024-09-20', 'Controlled midfield', 'N'),           -- Koke
(359, 359, '2024-09-20', 'Strong defense, 4 clearances', 'N'),  -- José Giménez
(360, 360, '2024-09-20', 'Made 5 saves', 'N');                  -- Jan Oblak





-- MatchEvent
INSERT INTO MatchEvent (MatchEventID, EventType, EventTime, PlayerID, MatchID, ImpactFantasyPoint)
VALUES
-- Football Events (FTB) for Matches 1-12

-- MatchID 1 (Teams 1 vs 2)
(1, 'Touchdown Pass', '00:12:34', 1, 1, 6),      -- Patrick Mahomes, Team 1
(2, 'Touchdown Reception', '00:12:34', 2, 1, 6), -- Travis Kelce, Team 1

-- MatchID 2 (Teams 3 vs 4)
(3, 'Rushing Touchdown', '00:08:15', 13, 2, 6), -- Joe Mixon, Team 3
(4, 'Interception', '00:05:45', 17, 2, -2),     -- AJ Brown, Team 4

-- MatchID 3 (Teams 5 vs 6)
(5, 'Field Goal', '00:02:20', 25, 3, 3),        -- Greg Zuerlein, Team 5
(6, 'Touchdown Pass', '00:09:50', 26, 3, 6),    -- Kirk Cousins, Team 6

-- MatchID 4 (Teams 7 vs 8)
(7, 'Touchdown Pass', '00:11:20', 31, 4, 6),    -- Player from Team 7
(8, 'Sack', '00:05:45', 38, 4, 2),              -- Player from Team 8

-- MatchID 5 (Teams 9 vs 10)
(9, 'Rushing Touchdown', '00:08:30', 43, 5, 6),  -- Player from Team 9
(10, 'Field Goal', '00:02:15', 50, 5, 3),        -- Player from Team 10

-- MatchID 6 (Teams 11 vs 12)
(11, 'Touchdown Reception', '00:06:50', 52, 6, 6), -- Player from Team 11
(12, 'Interception', '00:04:10', 56, 6, -2),       -- Player from Team 12

-- MatchID 7 (Teams 13 vs 14)
(13, 'Touchdown Pass', '00:09:10', 61, 7, 6),    -- Tom Brady, Team 13
(14, 'Interception', '00:03:45', 67, 7, -2),     -- Davante Adams, Team 14

-- MatchID 8 (Teams 15 vs 16)
(15, 'Field Goal', '00:07:30', 75, 8, 3),        -- Player from Team 15
(16, 'Touchdown Pass', '00:05:20', 76, 8, 6),    -- Aaron Rodgers, Team 16

-- MatchID 9 (Teams 17 vs 18)
(17, 'Rushing Touchdown', '00:12:15', 83, 9, 6), -- Player from Team 17
(18, 'Sack', '00:04:55', 88, 9, 2),              -- Player from Team 18

-- MatchID 10 (Teams 19 vs 20)
(19, 'Touchdown Pass', '00:08:40', 91, 10, 6),   -- Player from Team 19
(20, 'Interception', '00:02:30', 97, 10, -2),    -- Player from Team 20

-- MatchID 11 (Teams 21 vs 22)
(21, 'Touchdown Reception', '00:09:25', 102, 11, 6), -- Player from Team 21
(22, 'Field Goal', '00:03:10', 110, 11, 3),          -- Player from Team 22

-- MatchID 12 (Teams 23 vs 24)
(23, 'Rushing Touchdown', '00:07:15', 113, 12, 6),   -- Player from Team 23
(24, 'Sack', '00:01:50', 118, 12, 2),                -- Player from Team 24

-- Basketball Events (BB) for Matches 13-24

-- MatchID 13 (Teams 25 vs 26)
(25, '3-Point Made', '00:08:15', 121, 13, 3),       -- LeBron James, Team 25
(26, 'Assist', '00:08:15', 123, 13, 1),             -- Russell Westbrook, Team 25

-- MatchID 14 (Teams 27 vs 28)
(27, 'Block', '00:07:30', 134, 14, 2),              -- Deandre Ayton, Team 27
(28, 'Steal', '00:05:45', 136, 14, 2),              -- Giannis Antetokounmpo, Team 28

-- MatchID 15 (Teams 29 vs 30)
(29, 'Free Throw Made', '00:02:20', 141, 15, 1),    -- Luka Doncic, Team 29
(30, '3-Point Made', '00:01:50', 146, 15, 3),       -- Jayson Tatum, Team 30

-- MatchID 16 (Teams 31 vs 32)
(31, 'Rebound', '00:06:15', 151, 16, 1),            -- Joel Embiid, Team 31
(32, 'Assist', '00:06:15', 156, 16, 1),             -- Ja Morant, Team 32

-- MatchID 17 (Teams 33 vs 34)
(33, 'Steal', '00:09:05', 162, 17, 2),              -- Darius Garland, Team 33
(34, 'Turnover', '00:09:05', 167, 17, -1),          -- Zach LaVine, Team 34

-- MatchID 18 (Teams 35 vs 36)
(35, 'Block', '00:04:50', 174, 18, 2),              -- Clint Capela, Team 35
(36, '3-Point Made', '00:03:20', 176, 18, 3),       -- Damian Lillard, Team 36

-- MatchID 19 (Teams 37 vs 38)
(37, '2-Point Made', '00:07:45', 181, 19, 2),       -- Jimmy Butler, Team 37
(38, 'Assist', '00:07:45', 186, 19, 1),             -- Chris Paul, Team 38

-- MatchID 20 (Teams 39 vs 40)
(39, 'Dunk', '00:05:30', 192, 20, 2),               -- Anthony Edwards, Team 39
(40, 'Rebound', '00:05:30', 198, 20, 1),            -- John Wall, Team 40

-- MatchID 21 (Teams 41 vs 42)
(41, 'Free Throw Made', '00:01:10', 202, 21, 1),    -- Zach LaVine, Team 41
(42, '3-Point Made', '00:00:45', 206, 21, 3),       -- Donovan Mitchell, Team 42

-- MatchID 22 (Teams 43 vs 44)
(43, 'Assist', '00:09:50', 213, 22, 1),             -- CJ McCollum, Team 43
(44, 'Steal', '00:09:20', 218, 22, 2),              -- Kyle Kuzma, Team 44

-- MatchID 23 (Teams 45 vs 46)
(45, '3-Point Made', '00:08:00', 221, 23, 3),       -- Damian Lillard, Team 45
(46, 'Assist', '00:08:00', 227, 23, 1),             -- Bam Adebayo, Team 46

-- MatchID 24 (Teams 47 vs 48)
(47, 'Block', '00:07:15', 233, 24, 2),              -- Nikola Vucevic, Team 47
(48, 'Rebound', '00:07:15', 238, 24, 1),            -- Evan Mobley, Team 48

-- Soccer Events (SB) for Matches 25-36

-- MatchID 25 (Teams 49 vs 50)
(49, 'Goal', '00:23:15', 241, 25, 5),               -- Lionel Messi, Team 49
(50, 'Assist', '00:23:15', 244, 25, 3),             -- Josef Martinez, Team 49

-- MatchID 26 (Teams 51 vs 52)
(51, 'Goal', '00:30:10', 251, 26, 5),               -- Kylian Mbappé, Team 51
(52, 'Yellow Card', '00:45:00', 256, 26, -1),       -- Robert Lewandowski, Team 52

-- MatchID 27 (Teams 53 vs 54)
(53, 'Goal', '00:12:30', 261, 27, 5),               -- Erling Haaland, Team 53
(54, 'Assist', '00:12:30', 262, 27, 3),             -- Kevin De Bruyne, Team 53

-- MatchID 28 (Teams 55 vs 56)
(55, 'Goal', '00:45:00', 271, 28, 5),               -- Mohamed Salah, Team 55
(56, 'Penalty Saved', '01:10:00', 280, 28, 7),      -- Manuel Neuer, Team 56

-- MatchID 29 (Teams 57 vs 58)
(57, 'Goal', '01:00:00', 281, 29, 5),               -- Vinícius Júnior, Team 57
(58, 'Assist', '01:00:00', 282, 29, 3),             -- Luka Modrić, Team 57

-- MatchID 30 (Teams 59 vs 60)
(59, 'Goal', '00:15:20', 296, 30, 5),               -- Karim Benzema, Team 60
(60, 'Yellow Card', '01:25:00', 291, 30, -1),       -- André Carrillo, Team 59

-- MatchID 31 (Teams 61 vs 62)
(61, 'Goal', '00:55:10', 301, 31, 5),               -- Heung-Min Son, Team 61
(62, 'Assist', '00:55:10', 302, 31, 3),             -- James Maddison, Team 61

-- MatchID 32 (Teams 63 vs 64)
(63, 'Goal', '00:22:45', 316, 32, 5),               -- Victor Osimhen, Team 64
(64, 'Yellow Card', '00:40:00', 313, 32, -1),       -- Raheem Sterling, Team 63

-- MatchID 33 (Teams 65 vs 66)
(65, 'Goal', '01:08:30', 321, 33, 5),               -- Lautaro Martínez, Team 65
(66, 'Assist', '01:08:30', 327, 33, 3),             -- Paul Pogba, Team 66

-- MatchID 34 (Teams 67 vs 68)
(67, 'Goal', '00:30:00', 331, 34, 5),               -- Neymar Jr, Team 67
(68, 'Assist', '00:30:00', 338, 34, 3),             -- Anderson Talisca, Team 68

-- MatchID 35 (Teams 69 vs 70)
(69, 'Goal', '01:15:00', 346, 35, 5),               -- Sergio Ramos, Team 70
(70, 'Yellow Card', '01:20:00', 341, 35, -1),       -- Karim Benzema, Team 69

-- MatchID 36 (Teams 71 vs 72)
(71, 'Goal', '00:50:00', 356, 36, 5),               -- Antoine Griezmann, Team 72
(72, 'Assist', '00:50:00', 357, 36, 3);             -- Marcos Llorente, Team 72


-- Trade
INSERT INTO Trade (TradeID, TradeDate)
VALUES
(1, '2024-01-15'),
(2, '2024-01-20'),
(3, '2024-02-05'),
(4, '2024-02-12'),
(5, '2024-02-28'),
(6, '2024-03-03'),
(7, '2024-03-10'),
(8, '2024-03-18'),
(9, '2024-03-25'),
(10, '2024-04-05'),
(11, '2024-04-15'),
(12, '2024-04-22');


-- PlayerTrade
INSERT INTO PlayerTrade (TradeID, PlayerID, FromOrTo)
VALUES
(1, 10, 'From'),
(2, 20, 'From'),
(3, 30, 'From'),
(4, 40, 'From'),
(5, 50, 'From'),

(6, 60, 'From'),
(7, 70, 'From'),
(8, 80, 'From'),
(9, 90, 'From'),
(10, 100, 'From'),

(11, 110, 'From'),
(12, 120, 'From');



-- TeamTrade
INSERT INTO TeamTrade (TradeID, TeamID, InOrOut)
VALUES
(1, 1, 'Out'), (1, 2, 'In'),
(2, 3, 'Out'), (2, 4, 'In'),
(3, 5, 'Out'), (3, 6, 'In'),

(4, 7, 'Out'), (4, 8, 'In'),
(5, 9, 'Out'), (5, 10, 'In'),
(6, 11, 'Out'), (6, 12, 'In'),
(7, 13, 'Out'), (7, 14, 'In'),

(8, 15, 'Out'), (8, 16, 'In'),
(9, 17, 'Out'), (9, 18, 'In'),
(10, 19, 'Out'), (10, 20, 'In'),
(11, 21, 'Out'), (11, 22, 'In'),
(12, 23, 'Out'), (12, 24, 'In');


-- Waiver
INSERT INTO Waiver (WaiverID, WaiverStatus, WaiverPickupDate, TeamID, PlayerID)
VALUES
(1, 'P', '2024-01-05', 10, 49),
(2, 'A', '2024-01-10', 11, 54),
(3, 'D', '2024-01-15', 12, 59),
(4, 'A', '2024-01-20', 13, 64),
(5, 'P', '2024-01-25', 15, 74),
(6, 'D', '2024-02-01', 19, 94),
(7, 'A', '2024-02-05', 28, 139),
(8, 'P', '2024-02-10', 29, 144),
(9, 'A', '2024-02-15', 30, 149),
(10, 'D', '2024-02-20', 40, 199),
(11, 'P', '2024-02-25', 50, 249);






-- This procedure retrieves the public league the specified user manages(which means that the user is the commissioner), including team rankings within the league.

DELIMITER //

CREATE OR REPLACE PROCEDURE GetUserPublicLeaguesAndTeamRankings(IN inputUserID INT)
BEGIN
    SELECT 
        L.LeagueID,
        L.LeagueName,
        L.LeagueType,
        L.Commissioner,
        L.MaxNumber,
        L.DraftDate,
        T.TeamID,
        T.TeamName,
        T.Manager,
        T.TotalPoints,
        T.LeagueRanking
    FROM 
        League AS L
        JOIN Team AS T ON L.LeagueID = T.LeagueID
    WHERE 
        L.LeagueType = 'P' 
        AND L.Commissioner = inputUserID
    ORDER BY 
        L.LeagueID, T.LeagueRanking;
END //
DELIMITER ;

-- Example usage in SQL
-- CALL GetUserPublicLeaguesAndTeamRankings(1);




-- This procedure retrieves the private league the specified user manages(which means that the user is the commissioner), including team rankings within the league.

DELIMITER //

CREATE OR REPLACE PROCEDURE GetUserPrivateLeaguesAndTeamRankings(IN inputUserID INT)
BEGIN
    SELECT 
        L.LeagueID,
        L.LeagueName,
        L.LeagueType,
        L.Commissioner,
        L.MaxNumber,
        L.DraftDate,
        T.TeamID,
        T.TeamName,
        T.Manager,
        T.TotalPoints,
        T.LeagueRanking
    FROM 
        League AS L
        JOIN Team AS T ON L.LeagueID = T.LeagueID
    WHERE 
        L.LeagueType = 'R' 
        AND L.Commissioner = inputUserID
    ORDER BY 
        L.LeagueID, T.LeagueRanking;
END //

DELIMITER ;

-- Example usage in SQL
-- CALL GetUserPrivateLeaguesAndTeamRankings(25); 




-- This procedure retrieves match details for a specific team, including opponent team.

DELIMITER //

CREATE OR REPLACE PROCEDURE GetTeamMatchDetails(IN inputTeamID INT)
BEGIN
    SELECT 
        MD.MatchID,
        MD.MatchDate,
        MD.FinalScore,
        MD.Winner,
        MT1.HomeOrAway AS TeamHomeOrAway,
        T2.TeamName AS OpponentTeam
    FROM 
        MatchDetail AS MD
        JOIN MatchTeam AS MT1 ON MD.MatchID = MT1.MatchID
        JOIN MatchTeam AS MT2 ON MD.MatchID = MT2.MatchID
        JOIN Team AS T2 ON MT2.TeamID = T2.TeamID
    WHERE 
        MT1.TeamID = inputTeamID         
        AND MT2.TeamID != inputTeamID       
    ORDER BY 
        MD.MatchDate;
END //

DELIMITER ;

-- Example usage in SQL
-- CALL GetTeamMatchDetails(1); 



DELIMITER //

CREATE PROCEDURE GetMatches(
    IN p_sport CHAR(3),
    IN p_order_by VARCHAR(10)
)
BEGIN
    IF p_order_by = 'Date' THEN
        PREPARE stmt FROM '
            SELECT
                md.MatchID,
                md.MatchDate,
                md.FinalScore,
                md.Winner,
                t_home.TeamName AS HomeTeam,
                t_away.TeamName AS AwayTeam
            FROM
                MatchDetail md
            JOIN
                MatchTeam mt_home ON md.MatchID = mt_home.MatchID AND mt_home.HomeOrAway = ''Home''
            JOIN
                Team t_home ON mt_home.TeamID = t_home.TeamID
            JOIN
                MatchTeam mt_away ON md.MatchID = mt_away.MatchID AND mt_away.HomeOrAway = ''Away''
            JOIN
                Team t_away ON mt_away.TeamID = t_away.TeamID
            WHERE
                t_home.Sport = ?
                AND t_away.Sport = ?
            ORDER BY
                md.MatchDate DESC;
        ';
    ELSEIF p_order_by = 'Team' THEN
        PREPARE stmt FROM '
            SELECT
                md.MatchID,
                md.MatchDate,
                md.FinalScore,
                md.Winner,
                t_home.TeamName AS HomeTeam,
                t_away.TeamName AS AwayTeam
            FROM
                MatchDetail md
            JOIN
                MatchTeam mt_home ON md.MatchID = mt_home.MatchID AND mt_home.HomeOrAway = ''Home''
            JOIN
                Team t_home ON mt_home.TeamID = t_home.TeamID
            JOIN
                MatchTeam mt_away ON md.MatchID = mt_away.MatchID AND mt_away.HomeOrAway = ''Away''
            JOIN
                Team t_away ON mt_away.TeamID = t_away.TeamID
            WHERE
                t_home.Sport = ?
                AND t_away.Sport = ?
            ORDER BY
                t_home.TeamName ASC,
                t_away.TeamName ASC;
        ';
    ELSE
        -- 默认按日期排序
        PREPARE stmt FROM '
            SELECT
                md.MatchID,
                md.MatchDate,
                md.FinalScore,
                md.Winner,
                t_home.TeamName AS HomeTeam,
                t_away.TeamName AS AwayTeam
            FROM
                MatchDetail md
            JOIN
                MatchTeam mt_home ON md.MatchID = mt_home.MatchID AND mt_home.HomeOrAway = ''Home''
            JOIN
                Team t_home ON mt_home.TeamID = t_home.TeamID
            JOIN
                MatchTeam mt_away ON md.MatchID = mt_away.MatchID AND mt_away.HomeOrAway = ''Away''
            JOIN
                Team t_away ON mt_away.TeamID = t_away.TeamID
            WHERE
                t_home.Sport = ?
                AND t_away.Sport = ?
            ORDER BY
                md.MatchDate DESC;
        ';
    END IF;

    -- 执行准备好的语句
    EXECUTE stmt USING p_sport, p_sport;

    -- 释放准备好的语句
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;

-- This procedure retrieves all events that occurred in a specific match, including event details.
DELIMITER //

CREATE OR REPLACE PROCEDURE GetMatchEvents(
    IN p_MatchID NUMERIC(8),
    IN p_order_by VARCHAR(10)
)
BEGIN
    IF p_order_by = 'Player' THEN
        SELECT
            PlayerID,
            EventType,
            EventTime,
            ImpactFantasyPoint
        FROM
            MatchEvent
        WHERE
            MatchID = p_MatchID
        ORDER BY
            PlayerID ASC;
    ELSEIF p_order_by = 'Time' THEN
        SELECT
            PlayerID,
            EventType,
            EventTime,
            ImpactFantasyPoint
        FROM
            MatchEvent
        WHERE
            MatchID = p_MatchID
        ORDER BY
            EventTime ASC;
    ELSE
        -- sort by default order
        SELECT
            PlayerID,
            EventType,
            EventTime,
            ImpactFantasyPoint
        FROM
            MatchEvent
        WHERE
            MatchID = p_MatchID
        ORDER BY
            EventTime ASC;
    END IF;
END //

DELIMITER ;



-- Procedure to retrieve all teams managed by a specific user based on UserID

DELIMITER //

CREATE OR REPLACE PROCEDURE GetUserTeams(IN p_UserID INT)
BEGIN
    SELECT 
        t.TeamID,
        t.TeamName,
        t.LeagueID,
        l.LeagueName,
        t.TotalPoints,
        t.LeagueRanking,
        t.TeamStatus
    FROM 
        Team t
    JOIN 
        League l ON t.LeagueID = l.LeagueID
    WHERE 
        t.Manager = p_UserID;
END //

DELIMITER ;

-- Example usage in SQL
-- CALL GetUserTeams(1);




-- Procedure to retrieve all information for a team based on the TeamName
DELIMITER //

CREATE OR REPLACE PROCEDURE GetTeamInfoByName(IN p_TeamName VARCHAR(100))
BEGIN
    SELECT 
        t.TeamID,
        t.TeamName,
        t.LeagueID,
        l.LeagueName,
        l.LeagueType,
        l.DraftDate,
        t.Manager,
        u.FullName AS ManagerName,
        u.Email AS ManagerEmail,
        t.TotalPoints,
        t.LeagueRanking,
        t.TeamStatus
    FROM 
        Team t
    JOIN 
        League l ON t.LeagueID = l.LeagueID
    JOIN 
        User u ON t.Manager = u.UserID
    WHERE 
        t.TeamName = p_TeamName;
END //
DELIMITER ;

-- Example usage in SQL
-- CALL GetTeamInfoByName('Thunderbolts');

DELIMITER //


-- Procedure to login a user based on the input username/email and password
DELIMITER //

CREATE OR REPLACE PROCEDURE LoginUser(IN input_user VARCHAR(50), IN input_password VARCHAR(50))
BEGIN
    DECLARE user_count INT;
    DECLARE user_name VARCHAR(20);

    -- Check if the input_user matches either Email or UserName and verify the password
    SELECT COUNT(*), UserName INTO user_count, user_name
    FROM User
    WHERE (Email = input_user OR UserName = input_user)
      AND Pwd = input_password;
    
    -- If user exists and password matches
    IF user_count > 0 THEN
        SELECT CONCAT('Login successful. Welcome ', user_name, '!') AS Message;
    ELSE
        SELECT 'Invalid username/email or password' AS Message;
    END IF;
END //

DELIMITER ;

-- Example usage in SQL
-- Usage: CALL LoginUser('johndoe', 'password123');


-- This procedure registers a new user by inserting their details into the User table.
DELIMITER //

CREATE OR REPLACE PROCEDURE RegisterNewUser (
    IN fullName VARCHAR(100), 
    IN email VARCHAR(100), 
    IN userName VARCHAR(50), 
    IN password VARCHAR(100)
)
BEGIN
    INSERT INTO User (FullName, Email, UserName, Pwd, ProfileSetting)
    VALUES (fullName, email, userName, password, 'Public');

    SELECT 'Registration successful' AS Message;
END //

DELIMITER ;

-- Example usage in SQL
-- Usage: CALL RegisterNewUser('John Doe', 'john.doe@example.com', 'johndoe', 'password123');




-- Automatically add 20 points to the team's TotalPoints when a new player is added to the team
DELIMITER //

CREATE OR REPLACE TRIGGER AddPlayerPointsToTeam
AFTER INSERT ON Player
FOR EACH ROW
BEGIN
    IF NEW.TeamID IS NOT NULL THEN
        UPDATE Team
        SET TotalPoints = TotalPoints + 20
        WHERE TeamID = NEW.TeamID;
    END IF;
END //

DELIMITER ;




-- show all the drafts 

SELECT
    DraftID,
    Draft.LeagueID,
    Draft.DraftDate AS Date,
    DraftOrder,
    DraftStatus,
    LeagueType
FROM Draft
INNER JOIN League ON Draft.LeagueID = League.LeagueID
ORDER BY Draft.DraftDate;


DELIMITER //

CREATE OR REPLACE PROCEDURE StartDraft(
    IN p_LeagueID INT,            -- LeagueID
    IN p_DraftDate DATE,         -- Draft Date
    IN p_Order CHAR(1)            -- Type of draft order ('R' for round-robin, 'S' for snake)
)
BEGIN
    DECLARE v_DraftID INT;
    DECLARE team_count INT;
    DECLARE player_count INT DEFAULT 0;
    DECLARE round INT DEFAULT 1;
    DECLARE team_index INT;
    DECLARE current_team_id INT;
    DECLARE current_player_id INT;

    START TRANSACTION;

    -- Step 1: check if the LeagueID exists
    IF NOT EXISTS (SELECT 1 FROM League WHERE LeagueID = p_LeagueID) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'LeagueID does not exist.';
    END IF;

    -- Step 2: assign a new DraftID
    SELECT IFNULL(MAX(DraftID), 0) + 1 INTO v_DraftID FROM Draft;

    -- Step 3: insert a new draft record
    INSERT INTO Draft (DraftID, LeagueID, DraftDate, DraftOrder, DraftStatus)
    VALUES (v_DraftID, p_LeagueID, p_DraftDate, p_Order, 'I');

    -- Step 4: create a temporary table TempTeamOrder, order by LeagueRanking
    CREATE TEMPORARY TABLE TempTeamOrder AS
        SELECT TeamID, ROW_NUMBER() OVER (ORDER BY LeagueRanking ASC) AS RowNum
        FROM Team
        WHERE LeagueID = p_LeagueID;

    -- Step 5: get the number of teams
    SELECT COUNT(*) INTO team_count FROM TempTeamOrder;

    -- Step 6: check if there are teams in the league
    IF team_count = 0 THEN
        DROP TEMPORARY TABLE TempTeamOrder;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No teams found for the specified LeagueID.';
    END IF;

    -- Step 7: create a temporary table TempPlayerDraft, order by FantasyPoints
    CREATE TEMPORARY TABLE TempPlayerDraft AS
        SELECT PlayerID
        FROM Player
        WHERE AvaiStatus = 'A' -- 'A' is for Available
        ORDER BY FantasyPoints DESC;

    -- Step 8: start the draft process
    WHILE (SELECT COUNT(*) FROM TempPlayerDraft) > 0 DO
        SET team_index = CASE 
            WHEN p_Order = 'R' THEN (player_count % team_count) + 1
            WHEN p_Order = 'S' THEN 
                CASE 
                    WHEN round % 2 = 1 THEN (player_count % team_count) + 1 
                    ELSE (team_count - (player_count % team_count)) 
                END
            ELSE 1
        END;

        -- get TeamID for the current index
        SELECT TeamID INTO current_team_id 
        FROM TempTeamOrder 
        WHERE RowNum = team_index;

        -- get PlayerID for the current index
        SELECT PlayerID INTO current_player_id 
        FROM TempPlayerDraft 
        ORDER BY PlayerID 
        LIMIT 1;

        -- update Player's TeamID, DraftID and AvaiStatus
        UPDATE Player
        SET TeamID = current_team_id, DraftID = v_DraftID, AvaiStatus = 'U' -- 'U' 表示 Unavailable/Drafted
        WHERE PlayerID = current_player_id;

        -- delete the drafted player from TempPlayerDraft
        DELETE FROM TempPlayerDraft WHERE PlayerID = current_player_id;

        -- increment player_count
        SET player_count = player_count + 1;
        IF p_Order = 'S' AND player_count % team_count = 0 THEN
            SET round = round + 1;
        END IF;
    END WHILE;

    -- Step 9: update DraftStatus to 'C' (Completed)
    UPDATE Draft SET DraftStatus = 'C' WHERE DraftID = v_DraftID;

    -- Step 10: drop temporary tables
    DROP TEMPORARY TABLE IF EXISTS TempTeamOrder;
    DROP TEMPORARY TABLE IF EXISTS TempPlayerDraft;

    COMMIT;

    -- return DraftID
    SELECT v_DraftID AS DraftID;
END //

DELIMITER ;



-- Show all trades
-- Use:
-- CALL GetTrades('Name');  -- Ordered by player name
-- CALL GetTrades('Sport');  -- Ordered by sport
-- CALL GetTrades('Fantasy Points');  -- Ordered by fantasy points
DELIMITER //

CREATE OR REPLACE PROCEDURE GetTrades(
    IN order_by_field VARCHAR(50)
)
BEGIN
    IF order_by_field = 'Name' THEN
        SELECT 
            p.PlayerID,
            p.FullName,
            p.PhotoURL,
            p.RealTeam,
            pt.FromOrTo
        FROM 
            Trade t
        JOIN 
            PlayerTrade pt ON t.TradeID = pt.TradeID
        JOIN 
            Player p ON pt.PlayerID = p.PlayerID
        ORDER BY 
            p.FullName;
    ELSEIF order_by_field = 'Sport' THEN
        SELECT 
            p.PlayerID,
            p.FullName,
            p.PhotoURL,
            p.RealTeam,
            pt.FromOrTo
        FROM 
            Trade t
        JOIN 
            PlayerTrade pt ON t.TradeID = pt.TradeID
        JOIN 
            Player p ON pt.PlayerID = p.PlayerID
        ORDER BY 
            p.Sport;
    ELSEIF order_by_field = 'Fantasy Points' THEN
        SELECT 
            p.PlayerID,
            p.FullName,
            p.PhotoURL,
            p.RealTeam,
            pt.FromOrTo
        FROM 
            Trade t
        JOIN 
            PlayerTrade pt ON t.TradeID = pt.TradeID
        JOIN 
            Player p ON pt.PlayerID = p.PlayerID
        ORDER BY 
            p.FantasyPoints DESC;
    ELSE
        SELECT 'Invalid order_by_field. Use "Name", "Sport", or "Fantasy Points".' AS ErrorMessage;
    END IF;
END //
    
DELIMITER ;



-- Trade a player
-- Use:
-- CALL ExecuteTrade(user ID, trade out team ID, seller player ID, user player ID, date);
-- Example:
-- CALL ExecuteTrade(1, 2, 7, 11, '2024-11-12');
DELIMITER //

CREATE OR REPLACE PROCEDURE ExecuteTrade(
    IN p_UserID INT,              
    IN p_SellerTeamID INT,        
    IN p_PlayerID INT,           
    IN p_YourPlayerID INT,       
    IN p_TradeDate DATE         
)
BEGIN
    DECLARE v_BuyerTeamID INT;   
    DECLARE v_NewTradeID INT;     

    START TRANSACTION;

    -- get the buyer team ID
    SELECT TeamID INTO v_BuyerTeamID
    FROM Team
    WHERE Manager = p_UserID
    LIMIT 1;

    -- validate the buyer team
    IF v_BuyerTeamID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Buyer team not found for the given UserID.';
    END IF;

    -- insert a new trade record
    INSERT INTO Trade (TradeDate) VALUES (p_TradeDate);
    SET v_NewTradeID = @new_trade_id;  -- use trigger to get the new trade ID

    -- update the player's team ID and availability status to the buyer team
    UPDATE Player
    SET TeamID = v_BuyerTeamID, AvaiStatus = 'U'
    WHERE PlayerID = p_PlayerID;

    -- update the user's player's team ID and availability status to the seller team
    UPDATE Player
    SET TeamID = p_SellerTeamID, AvaiStatus = 'A'
    WHERE PlayerID = p_YourPlayerID;

    -- insert player trade records
    INSERT INTO PlayerTrade (TradeID, PlayerID, FromOrTo)
    VALUES
        (v_NewTradeID, p_PlayerID, 'To'),
        (v_NewTradeID, p_YourPlayerID, 'From');

    -- insert team trade records
    INSERT INTO TeamTrade (TradeID, TeamID, InOrOut)
    VALUES
        (v_NewTradeID, v_BuyerTeamID, 'In'),
        (v_NewTradeID, p_SellerTeamID, 'Out');

    COMMIT;
END //

DELIMITER ;


-- Show Match events for a given match id
-- Use:
-- CALL GetMatchEvents(MatchID, 'Player');  -- order by PlayerID
-- CALL GetMatchEvents(MatchID, 'Time'); -- order by EventTime
DELIMITER //

CREATE OR REPLACE PROCEDURE GetMatchEvents(
    IN input_match_id INT,
    IN order_by_field VARCHAR(50)
)
BEGIN
    IF order_by_field = 'Player' THEN
        SELECT 
            PlayerID, 
            EventType, 
            EventTime, 
            ImpactFantasyPoint
        FROM 
            MatchEvent
        WHERE 
            MatchID = input_match_id
        ORDER BY 
            PlayerID;
    ELSEIF order_by_field = 'Time' THEN
        SELECT 
            PlayerID, 
            EventType, 
            EventTime, 
            ImpactFantasyPoint
        FROM 
            MatchEvent
        WHERE 
            MatchID = input_match_id
        ORDER BY 
            EventTime;
    ELSE
        SELECT 'Invalid order_by_field. Use "Player" or "Time".' AS ErrorMessage;
    END IF;
END //

DELIMITER ;


--Show general statistics for players
-- Use:
-- CALL GetAllPlayerStats('Name');  -- order by PlayerName
-- CALL GetAllPlayerStats('Fantasy Points'); -- order by FantasyPoints
DELIMITER //

CREATE OR REPLACE PROCEDURE GetAllPlayerStats(
    IN order_by_field VARCHAR(50)
)
BEGIN
    IF order_by_field = 'Name' THEN
        SELECT DISTINCT
            p.PlayerID,
            p.FullName,
            p.PhotoURL,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        ORDER BY 
            p.FullName ASC;
    ELSEIF order_by_field = 'Fantasy Points' THEN
        SELECT DISTINCT
            p.PlayerID,
            p.FullName,
            p.PhotoURL,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        ORDER BY 
            p.FantasyPoints DESC;  -- 通常 Fantasy Points 需要降序排序
    ELSEIF order_by_field = 'Sport' THEN
        SELECT DISTINCT
            p.PlayerID,
            p.FullName,
            p.PhotoURL,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        ORDER BY 
            p.Sport ASC;
    ELSE
        -- if the order_by_field is invalid, return an error message
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid order_by_field. Use "Name", "Fantasy Points", or "Sport".';
    END IF;
END //

DELIMITER ;

--Show player details for a given player id
-- Use:
-- CALL GetPlayerDetails(PlayerID);

DELIMITER //

CREATE OR REPLACE PROCEDURE GetPlayerDetails(
    IN p_PlayerID NUMERIC(8)
)
BEGIN
    SELECT 
        p.PlayerID,
        p.FullName,
        p.PhotoURL,
        p.Position,
        p.RealTeam,
        p.FantasyPoints,
        p.AvaiStatus,
        GROUP_CONCAT(ps.GameDate ORDER BY ps.GameDate DESC SEPARATOR ', ') AS GameDates
    FROM 
        Player p
    LEFT JOIN 
        PlayerStats ps ON p.PlayerID = ps.PlayerID
    WHERE 
        p.PlayerID = p_PlayerID
    GROUP BY
        p.PlayerID, 
        p.FullName, 
        p.PhotoURL, 
        p.Position, 
        p.RealTeam, 
        p.FantasyPoints, 
        p.AvaiStatus;
END //

DELIMITER ;





--Show player status for a given league id
-- Use:
-- Sort by player name
-- CALL GetPlayerStatus(1, 'name');
-- Sort by sport type
-- CALL GetPlayerStatus(1, 'sport');
-- Sort by fantasy points
-- CALL GetPlayerStatus(1, 'fantasy points');
DELIMITER //
CREATE OR REPLACE PROCEDURE GetPlayerStatus(
    IN p_LeagueID INT,
    IN p_sort_by VARCHAR(20)
)
BEGIN
    IF p_sort_by = 'name' THEN
        SELECT Player.FullName, Player.AvaiStatus, Player.FantasyPoints
        FROM Player
        JOIN Team ON Player.TeamID = Team.TeamID
        JOIN League ON Team.LeagueID = League.LeagueID
        WHERE League.LeagueID = p_LeagueID
        ORDER BY Player.FullName;
    ELSEIF p_sort_by = 'sport' THEN
        SELECT Player.FullName, Player.AvaiStatus, Player.FantasyPoints
        FROM Player
        JOIN Team ON Player.TeamID = Team.TeamID
        JOIN League ON Team.LeagueID = League.LeagueID
        WHERE League.LeagueID = p_LeagueID
        ORDER BY Player.Sport;
    ELSEIF p_sort_by = 'fantasy points' THEN
        SELECT Player.FullName, Player.AvaiStatus, Player.FantasyPoints
        FROM Player
        JOIN Team ON Player.TeamID = Team.TeamID
        JOIN League ON Team.LeagueID = League.LeagueID
        WHERE League.LeagueID = p_LeagueID
        ORDER BY Player.FantasyPoints DESC;
    ELSE
        SELECT 'Invalid sort_by_field. Use "name", "sport", or "fantasy points".' AS ErrorMessage;
    END IF;
END //

DELIMITER ;

--Show player status for a given player id
-- Use:
-- CALL GetPlayerStatusByID(Player_iD);
DELIMITER //

CREATE OR REPLACE PROCEDURE GetPlayerStatusByID(
    IN p_PlayerID INT
)
BEGIN
    SELECT 
        Player.PlayerID,
        Player.FullName,
        Player.Sport,
        Player.Position,
        Player.RealTeam,
        Player.FantasyPoints,
        Player.AvaiStatus,
        Player.PhotoURL
    FROM Player
    WHERE Player.PlayerID = p_PlayerID;
END//

DELIMITER ;

-- Procedure to get all players available for waiver
DELIMITER //
CREATE OR REPLACE PROCEDURE GetWaiverPlayers(IN sort_order VARCHAR(50))
BEGIN
    IF sort_order = 'Name' THEN
        SELECT 
            p.PlayerID,
            p.FullName,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        WHERE 
            p.PlayerID IN (SELECT PlayerID FROM Waiver WHERE WaiverStatus = 'P')
        ORDER BY 
            p.FullName;
    ELSEIF sort_order = 'Sport' THEN
        SELECT 
            p.PlayerID,
            p.FullName,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        WHERE 
            p.PlayerID IN (SELECT PlayerID FROM Waiver WHERE WaiverStatus = 'P')
        ORDER BY 
            p.Sport;
    ELSEIF sort_order = 'FantasyPoints' THEN
        SELECT 
            p.PlayerID,
            p.FullName,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        WHERE 
            p.PlayerID IN (SELECT PlayerID FROM Waiver WHERE WaiverStatus = 'P')
        ORDER BY 
            p.FantasyPoints DESC;
    ELSE
        -- 默认按名称排序
        SELECT 
            p.PlayerID,
            p.FullName,
            p.Sport,
            p.FantasyPoints
        FROM 
            Player p
        WHERE 
            p.PlayerID IN (SELECT PlayerID FROM Waiver WHERE WaiverStatus = 'P')
        ORDER BY 
            p.FullName;
    END IF;
END //

DELIMITER ;

-- Example usage in SQL
-- CALL GetWaiverPlayers('FantasyPoints');

-- Procedure to get waiver details by Waiver ID
DELIMITER //

CREATE OR REPLACE PROCEDURE GetWaiverPlayers(IN sort_order VARCHAR(50))
BEGIN
    SELECT 
        w.WaiverID,
        p.PlayerID,
        p.FullName,
        p.Sport,
        p.FantasyPoints
    FROM 
        Player p
    JOIN 
        Waiver w ON p.PlayerID = w.PlayerID
    WHERE 
        w.WaiverStatus = 'P'
    ORDER BY 
        CASE 
            WHEN sort_order = 'Name' THEN p.FullName
            WHEN sort_order = 'Sport' THEN p.Sport
            WHEN sort_order = 'FantasyPoints' THEN p.FantasyPoints
            ELSE p.FullName
        END ASC;
END //

DELIMITER ;

-- Example usage in SQL
-- CALL GetWaiverDetails(1);
DELIMITER //

CREATE PROCEDURE GetWaiverDetails(IN waiver_id INT)
BEGIN
    SELECT 
        w.WaiverID,
        w.TeamID,
        w.PlayerID,
        w.WaiverStatus,
        w.WaiverPickupDate
    FROM 
        Waiver w
    WHERE 
        w.WaiverID = waiver_id;
END //

DELIMITER ;


-- Procedure to update waiver status

DELIMITER //

CREATE OR REPLACE PROCEDURE UpdateWaiverStatus(IN waiver_id INT, IN new_status CHAR(1))
BEGIN
    -- 验证 new_status 是否有效
    IF new_status NOT IN ('P', 'A', 'D') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid new_status. Use ''P'', ''A'', or ''D''.';
    ELSE
        UPDATE Waiver
        SET WaiverStatus = new_status
        WHERE WaiverID = waiver_id;
        
        SELECT CONCAT('Waiver ID ', waiver_id, ' has been updated to status ', 
                      CASE new_status
                          WHEN 'P' THEN 'Pending'
                          WHEN 'A' THEN 'Approved'
                          WHEN 'D' THEN 'Denied'
                      END) AS UpdateMessage;
    END IF;
END //

DELIMITER ;

-- Example usage in SQL
-- CALL UpdateWaiverStatus(1, 'Approved');

-- Trigger to update waiver status to approved when a new player is added to the waiver

DELIMITER //

CREATE OR REPLACE TRIGGER AutoApproveWaiver
BEFORE INSERT ON Waiver
FOR EACH ROW
BEGIN
    IF NEW.WaiverStatus = 'P' THEN
        SET NEW.WaiverStatus = 'A';
    END IF;
END //

DELIMITER ;