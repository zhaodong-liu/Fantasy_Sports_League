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
(1, 'John Doe', 'john.doe@example.com', 'johndoe', 'password123', 'Public', 'U'),
(2, 'Jane Smith', 'jane.smith@example.com', 'janesmith', 'securepass456', 'Private', 'U'),
(3, 'Alice Johnson', 'alice.johnson@example.com', 'alicej', 'mypassword789', 'Public', 'U'),
(4, 'Bob Brown', 'bob.brown@example.com', 'bobb', 'qwerty321', 'Public', 'U'),
(5, 'Charlie Davis', 'charlie.davis@example.com', 'charlied', 'charlie123', 'Private', 'U'),
(6, 'David Evans', 'david.evans@example.com', 'davidevans', 'passwordabc', 'Public', 'U'),
(7, 'Emma Wilson', 'emma.wilson@example.com', 'emmaw', 'emma456', 'Private', 'U'),
(8, 'Frank Taylor', 'frank.taylor@example.com', 'frankt', 'password789', 'Public', 'U'),
(9, 'Grace Lee', 'grace.lee@example.com', 'gracelee', 'mypassword123', 'Private', 'U'),
(10, 'Henry Walker', 'henry.walker@example.com', 'henryw', 'walker321', 'Public', 'U'),
(11, 'Isabella Scott', 'isabella.scott@example.com', 'isabellas', 'passwordiscool', 'Private', 'U'),
(12, 'Jack White', 'jack.white@example.com', 'jackw', 'jackpass123', 'Public', 'U'),
(13, 'Lily Hall', 'lily.hall@example.com', 'lilyh', 'lilypass456', 'Private', 'U'),
(14, 'Mark Green', 'mark.green@example.com', 'markg', 'markpass789', 'Public', 'U'),
(15, 'Nancy Young', 'nancy.young@example.com', 'nancyy', 'nancy1234', 'Private', 'U'),
(16, 'Oliver King', 'oliver.king@example.com', 'oliverk', 'oliverpass567', 'Public', 'U'),
(17, 'Paul Harris', 'paul.harris@example.com', 'paulh', 'pharris321', 'Private', 'U'),
(18, 'Rachel Martinez', 'rachel.martinez@example.com', 'rachelm', 'rmartinez123', 'Public', 'U'),
(19, 'Sam Thompson', 'sam.thompson@example.com', 'samt', 'sammy789', 'Private', 'U'),
(20, 'Tina Turner', 'tina.turner@example.com', 'tinat', 'tinapass987', 'Public', 'U'),
(21, 'Uma Patel', 'uma.patel@example.com', 'umap', 'umapass456', 'Private', 'U'),
(22, 'Victor Gomez', 'victor.gomez@example.com', 'victorg', 'victorpass789', 'Public', 'U'),
(23, 'Wendy Brooks', 'wendy.brooks@example.com', 'wendyb', 'wendypass123', 'Private', 'U'),
(24, 'Xavier Powell', 'xavier.powell@example.com', 'xavierp', 'xavierpassword', 'Public', 'U'),
(25, 'Yara Reed', 'yara.reed@example.com', 'yarar', 'yarapass456', 'Private', 'U');

-- League
INSERT INTO League (LeagueID, LeagueName, LeagueType, Commissioner, MaxNumber, DraftDate, Sport)
VALUES
(1, 'American Football League (F)', 'P', 1, 12, '2024-07-25', 'FTB'),
(2, 'College Football Fantasy (F)', 'R', 14, 25, '2024-01-02', 'FTB'),
(3, 'Local Football Tournament (F)', 'P', 24, 8, '2024-02-27', 'FTB'),
(4, 'National Football League (F)', 'P', 1, 10, '2024-01-15', 'FTB'),
(5, 'Professional Football League (F)', 'R', 17, 20, '2024-04-28', 'FTB'),
(6, 'Regional Football League (F)', 'P', 21, 10, '2024-09-20', 'FTB'),
(7, 'Super Bowl Fantasy (F)', 'P', 6, 14, '2024-05-15', 'FTB'),

(8, 'NCAA Basketball League (B)', 'P', 15, 22, '2024-11-11', 'BB'),
(9, 'All-Star Basketball League (B)', 'P', 7, 18, '2024-08-03', 'BB'),
(10, 'Elite Basketball League (B)', 'R', 5, 20, '2024-10-01', 'BB'),
(11, 'International Basketball League (B)', 'R', 8, 15, '2024-11-05', 'BB'),
(12, 'Minor League Basketball (B)', 'R', 22, 14, '2024-12-01', 'BB'),
(13, 'NBA Fantasy League (B)', 'R', 2, 12, '2024-02-10', 'BB'),
(14, 'Youth Basketball League (B)', 'P', 12, 12, '2024-09-22', 'BB'),

(15, 'Champions Fantasy League (S)', 'R', 25, 16, '2024-12-15', 'SB'),
(16, 'City Soccer League (S)', 'P', 23, 20, '2024-03-12', 'SB'),
(17, 'Continental Soccer Cup (S)', 'P', 16, 10, '2024-05-08', 'SB'),
(18, 'Euro Soccer Fantasy (S)', 'P', 13, 14, '2024-06-30', 'SB'),
(19, 'North American Soccer League (S)', 'P', 18, 15, '2024-07-09', 'SB'),
(20, 'Premier Soccer League (S)', 'P', 3, 8, '2024-03-05', 'SB'),
(21, 'Pro Soccer League (S)', 'P', 7, 10, '2024-08-15', 'SB'),
(22, 'World Cup Fantasy League (S)', 'P', 4, 16, '2024-06-20', 'SB'),
(23, 'World Fantasy Soccer (S)', 'R', 20, 12, '2024-10-15', 'SB'),
(24, 'World Soccer League (S)', 'P', 15, 20, '2024-04-10', 'SB'),
(25, 'Fantasy Premier League (S)', 'R', 25, 18, '2024-03-18', 'SB');


-- Team
INSERT INTO Team (TeamID, TeamName, Manager, LeagueID, TotalPoints, LeagueRanking, TeamStatus, Sport)
VALUES
(1, 'Thunderbolts', 1, 1, 1200, 1, 'A', 'FTB'),
(2, 'Storm Chasers', 2, 1, 1150, 2, 'A', 'FTB'),
(3, 'Mighty Eagles', 3, 1, 1100, 3, 'I', 'FTB'),
(4, 'Iron Giants', 4, 1, 1050, 4, 'A', 'FTB'),
(5, 'Golden Griffins', 5, 1, 1000, 5, 'A', 'FTB'),
(6, 'Shadow Wolves', 6, 1, 950, 6, 'I', 'FTB'),

(7, 'Fire Falcons', 7, 9, 900, 1, 'A', 'BB'),
(8, 'Aqua Warriors', 8, 9, 850, 2, 'I', 'BB'),
(9, 'Steel Dragons', 9, 9, 820, 3, 'A', 'BB'),
(10, 'Blazing Suns', 10, 9, 800, 4, 'I', 'BB'),
(11, 'Electric Tigers', 11, 9, 780, 5, 'A', 'BB'),
(12, 'Silver Hawks', 12, 9, 770, 6, 'A', 'BB'),
(13, 'Mystic Phoenix', 13, 9, 750, 7, 'I', 'BB'),
(14, 'Frost Bears', 14, 9, 740, 8, 'A', 'BB'),

(15, 'Crystal Knights', 15, 24, 730, 1, 'I', 'SB'),
(16, 'Raging Bulls', 16, 24, 720, 2, 'A', 'SB'),
(17, 'Shadow Panthers', 17, 24, 710, 3, 'A', 'SB'),
(18, 'Thunder Sharks', 18, 24, 700, 4, 'I', 'SB'),
(19, 'Volcano Cobras', 19, 24, 690, 5, 'A', 'SB'),
(20, 'Lava Titans', 20, 24, 680, 6, 'I', 'SB'),
(21, 'Phantom Reapers', 21, 24, 670, 7, 'A', 'SB'),
(22, 'Inferno Foxes', 22, 24, 660, 8, 'I', 'SB'),
(23, 'Glacier Owls', 23, 24, 650, 9, 'A', 'SB'),
(24, 'Tempest Lions', 24, 24, 640, 10, 'I', 'SB'),
(25, 'Electric Lions', 25, 25, 640, 10, 'I', 'SB');




-- Draft
INSERT INTO Draft (DraftID, LeagueID, DraftDate, DraftOrder, DraftStatus)
VALUES
(1, 1, '2024-01-20', 'R', 'C'),
(2, 2, '2024-02-15', 'S', 'I'),
(3, 3, '2024-03-10', 'R', 'C'),
(4, 4, '2024-04-05', 'S', 'I'),
(5, 5, '2024-05-01', 'R', 'C'),
(6, 6, '2024-06-12', 'S', 'C'),
(7, 7, '2024-07-09', 'R', 'I'),
(8, 8, '2024-08-20', 'S', 'C'),
(9, 9, '2024-09-15', 'R', 'C'),
(10, 10, '2024-10-25', 'S', 'I'),
(11, 11, '2024-11-10', 'R', 'C'),
(12, 12, '2024-12-05', 'S', 'C'),
(13, 13, '2024-03-15', 'R', 'I'),
(14, 14, '2024-04-22', 'S', 'C'),
(15, 15, '2024-05-30', 'R', 'C'),
(16, 16, '2024-06-17', 'S', 'I'),
(17, 17, '2024-07-05', 'R', 'C'),
(18, 18, '2024-08-10', 'S', 'C'),
(19, 19, '2024-09-01', 'R', 'I'),
(20, 20, '2024-10-14', 'S', 'C'),
(21, 21, '2024-11-19', 'R', 'I'),
(22, 22, '2024-12-09', 'S', 'C'),
(23, 23, '2024-01-29', 'R', 'I'),
(24, 24, '2024-02-15', 'S', 'C'),
(25, 25, '2024-03-18', 'R', 'I');


-- Player
-- Football Players
INSERT INTO Player (PlayerID, FullName, PhotoURL, Sport, Position, RealTeam, FantasyPoints, AvaiStatus, TeamID, DraftID)
VALUES
(1, 'Patrick Mahomes', '1', 'FTB', 'QB', 'Kansas City Chiefs', 280, 'A', 1, 1),
(2, 'Tom Brady', '2', 'FTB', 'QB', 'Tampa Bay Buccaneers', 270, 'A', 1, 1),
(3, 'Aaron Rodgers', '3', 'FTB', 'QB', 'Green Bay Packers', 260, 'A', 2, 1),
(4, 'Russell Wilson', '4', 'FTB', 'QB', 'Denver Broncos', 250, 'A', 2, 1),
(5, 'Saquon Barkley', '5', 'FTB', 'RB', 'New York Giants', 240, 'A', 3, 1),
(6, 'Ezekiel Elliott', '6', 'FTB', 'RB', 'Dallas Cowboys', 230, 'A', 3, 1),
(7, 'Travis Kelce', '7', 'FTB', 'TE', 'Kansas City Chiefs', 220, 'A', 4, 1),
(8, 'Davante Adams', '8', 'FTB', 'WR', 'Green Bay Packers', 210, 'A', 4, 1),
(9, 'Derrick Henry', '9', 'FTB', 'RB', 'Tennessee Titans', 230, 'A', 5, 1),
(10, 'DeAndre Hopkins', '10', 'FTB', 'WR', 'Arizona Cardinals', 220, 'A', 5, 1),
(11, 'Josh Allen', '11', 'FTB', 'QB', 'Buffalo Bills', 240, 'A', 6, 1),
(12, 'Alvin Kamara', '12', 'FTB', 'RB', 'New Orleans Saints', 230, 'A', 6, 1),
(13, 'Kyler Murray', '13', 'FTB', 'QB', 'Arizona Cardinals', 220, 'A', 1, 1),
(14, 'Nick Chubb', '14', 'FTB', 'RB', 'Cleveland Browns', 210, 'A', 1, 1),
(15, 'George Kittle', '15', 'FTB', 'TE', 'San Francisco 49ers', 200, 'A', 2, 1),
(16, 'Tyreek Hill', '16', 'FTB', 'WR', 'Miami Dolphins', 210, 'A', 2, 1),
(17, 'Lamar Jackson', '17', 'FTB', 'QB', 'Baltimore Ravens', 240, 'A', 3, 1),
(18, 'Stefon Diggs', '18', 'FTB', 'WR', 'Buffalo Bills', 230, 'A', 4, 1),
(19, 'Justin Jefferson', '19', 'FTB', 'WR', 'Minnesota Vikings', 220, 'A', 5, 1),
(20, 'Dalvin Cook', '20', 'FTB', 'RB', 'Minnesota Vikings', 210, 'A', 6, 1);

-- Basketball Players
INSERT INTO Player (PlayerID, FullName, PhotoURL, Sport, Position, RealTeam, FantasyPoints, AvaiStatus, TeamID, DraftID)
VALUES
(21, 'LeBron James', '21', 'BB', 'FWD', 'Los Angeles Lakers', 320, 'A', 11, 2),
(22, 'Stephen Curry', '22', 'BB', 'GUA', 'Golden State Warriors', 310, 'A', 11, 2),
(23, 'Kevin Durant', '23', 'BB', 'FWD', 'Brooklyn Nets', 300, 'A', 12, 2),
(24, 'Giannis Antetokounmpo', '24', 'BB', 'FWD', 'Milwaukee Bucks', 290, 'A', 12, 2),
(25, 'James Harden', '25', 'BB', 'GUA', 'Philadelphia 76ers', 280, 'A', 13, 2),
(26, 'Anthony Davis', '26', 'BB', 'CEN', 'Los Angeles Lakers', 270, 'A', 13, 2),
(27, 'Damian Lillard', '27', 'BB', 'GUA', 'Portland Trail Blazers', 260, 'A', 14, 2),
(28, 'Nikola Jokic', '28', 'BB', 'CEN', 'Denver Nuggets', 250, 'A', 14, 2),
(29, 'Kawhi Leonard', '29', 'BB', 'FWD', 'Los Angeles Clippers', 240, 'A', 7, 2),
(30, 'Paul George', '30', 'BB', 'FWD', 'Los Angeles Clippers', 230, 'A', 7, 2),
(31, 'Luka Doncic', '31', 'BB', 'GUA', 'Dallas Mavericks', 320, 'A', 8, 2),
(32, 'Jayson Tatum', '32', 'BB', 'FWD', 'Boston Celtics', 310, 'A', 8, 2),
(33, 'Joel Embiid', '33', 'BB', 'CEN', 'Philadelphia 76ers', 300, 'A', 8, 2),
(34, 'Chris Paul', '34', 'BB', 'GUA', 'Phoenix Suns', 290, 'A', 9, 2),
(35, 'Jimmy Butler', '35', 'BB', 'FWD', 'Miami Heat', 280, 'A', 9, 2),
(36, 'Donovan Mitchell', '36', 'BB', 'GUA', 'Utah Jazz', 270, 'A', 9, 2),
(37, 'Zion Williamson', '37', 'BB', 'FWD', 'New Orleans Pelicans', 260, 'A', 10, 2),
(38, 'Karl-Anthony Towns', '38', 'BB', 'CEN', 'Minnesota Timberwolves', 250, 'A', 10, 2),
(39, 'Bradley Beal', '39', 'BB', 'GUA', 'Washington Wizards', 240, 'A', 10, 2),
(40, 'Devin Booker', '40', 'BB', 'GUA', 'Phoenix Suns', 230, 'A', 10, 2);

-- Soccer Players
INSERT INTO Player (PlayerID, FullName, PhotoURL, Sport, Position, RealTeam, FantasyPoints, AvaiStatus, TeamID, DraftID)
VALUES
(41, 'Lionel Messi', '41', 'SB', 'FW', 'Paris Saint-Germain', 340, 'A', 21, 3),
(42, 'Cristiano Ronaldo', '42', 'SB', 'FW', 'Manchester United', 330, 'A', 21, 3),
(43, 'Neymar Jr', '43', 'SB', 'FW', 'Paris Saint-Germain', 320, 'A', 22, 3),
(44, 'Kylian Mbappe', '44', 'SB', 'FW', 'Paris Saint-Germain', 310, 'A', 22, 3),
(45, 'Luka Modric', '45', 'SB', 'MF', 'Real Madrid', 300, 'A', 23, 3),
(46, 'Harry Kane', '46', 'SB', 'FW', 'Tottenham Hotspur', 290, 'A', 23, 3),
(47, 'Mohamed Salah', '47', 'SB', 'FW', 'Liverpool', 280, 'A', 24, 3),
(48, 'Virgil van Dijk', '48', 'SB', 'DF', 'Liverpool', 270, 'A', 24, 3),
(49, 'Sergio Ramos', '49', 'SB', 'DF', 'Paris Saint-Germain', 260, 'A', 20, 3),
(50, 'Eden Hazard', '50', 'SB', 'FW', 'Real Madrid', 250, 'A', 20, 3),
(51, 'Raheem Sterling', '51', 'SB', 'FW', 'Manchester City', 240, 'A', NULL, NULL),
(52, 'Phil Foden', '52', 'SB', 'MF', 'Manchester City', 230, 'A', NULL, NULL),
(53, 'Karim Benzema', '53', 'SB', 'FW', 'Real Madrid', 320, 'A', NULL, NULL),
(54, 'Erling Haaland', '54', 'SB', 'FW', 'Manchester City', 310, 'A', NULL, NULL),
(55, 'Robert Lewandowski', '55', 'SB', 'FW', 'Barcelona', 300, 'A', NULL, NULL),
(56, 'Jadon Sancho', '56', 'SB', 'FW', 'Manchester United', 290, 'A', NULL, NULL),
(57, 'Gareth Bale', '57', 'SB', 'FW', 'Los Angeles FC', 280, 'A', NULL, NULL),
(58, 'Thiago Silva', '58', 'SB', 'DF', 'Chelsea', 270, 'A', NULL, NULL),
(59, 'Marcus Rashford', '59', 'SB', 'FW', 'Manchester United', 260, 'A', NULL, NULL),
(60, 'Paul Pogba', '60', 'SB', 'MF', 'Juventus', 250, 'A', NULL, NULL);

-- MatchDetail
INSERT INTO MatchDetail (MatchID, MatchDate, FinalScore, Winner)
VALUES
(1, '2024-01-25', '32-2', 'Thunderbolts'),
(2, '2024-02-10', '21-14', 'Mighty Eagles'),
(3, '2024-03-05', '19-5', 'Golden Griffins'),
(4, '2024-04-15', '74-63', 'Fire Falcons'),
(5, '2024-05-20', '85-71', 'Steel Dragons'),
(6, '2024-06-12', '73-73', 'Draw'),
(7, '2024-07-09', '95-81', 'Mystic Phoenix'),
(8, '2024-08-15', '4-1', 'Crystal Knights'),
(9, '2024-09-20', '3-1', 'Shadow Panthers'),
(10, '2024-10-11', '4-4', 'Draw'),
(11, '2024-11-05', '2-2', 'Draw'),
(12, '2024-12-10', '5-3', 'Glacier Owls');



-- MatchTeam
INSERT INTO MatchTeam (MatchID, TeamID, HomeOrAway)
VALUES
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
(12, 23, 'Home'), (12, 24, 'Away');



INSERT INTO PlayerStats (StatsID, PlayerID, GameDate, PerformanceStats, InjuryStatus)
VALUES
-- Football Players
(1, 1, '2024-01-25', 'Passed for 300 yards', 'N'),
(2, 2, '2024-02-10', 'Passed for 280 yards', 'N'),
(3, 3, '2024-03-05', 'Passed for 270 yards', 'N'),
(4, 4, '2024-04-15', 'Passed for 250 yards', 'N'),
(5, 5, '2024-05-20', 'Rushed for 100 yards', 'N'),
(6, 6, '2024-06-12', 'Rushed for 90 yards', 'N'),
(7, 7, '2024-07-09', 'Caught 120 yards', 'N'),
(8, 8, '2024-08-15', 'Caught 110 yards', 'Y'), -- 'Injured' -> 'Y'
(9, 9, '2024-09-20', 'Rushed for 130 yards', 'N'),
(10, 10, '2024-10-11', 'Caught 90 yards', 'N'),



-- Basketball Players
(11, 21, '2024-01-25', 'Scored 30 points, 8 rebounds', 'N'),
(12, 22, '2024-02-05', 'Scored 35 points, 5 assists', 'N'),
(13, 23, '2024-03-10', 'Scored 28 points, 7 rebounds', 'N'),
(14, 24, '2024-04-12', 'Scored 33 points, 12 rebounds', 'N'),
(15, 25, '2024-05-08', 'Scored 25 points, 9 assists', 'Y'), -- 'Injured' -> 'Y'
(16, 26, '2024-06-20', 'Scored 27 points, 11 rebounds', 'N'),
(17, 27, '2024-07-15', 'Scored 29 points, 4 assists', 'N'),
(18, 28, '2024-08-09', 'Scored 31 points, 10 rebounds', 'N'),
(19, 29, '2024-09-18', 'Scored 20 points, 6 rebounds', 'N'),
(20, 30, '2024-10-30', 'Scored 22 points, 5 assists', 'N'),

-- Soccer Players
(21, 41, '2024-01-18', 'Scored 2 goals', 'N'),
(22, 42, '2024-02-21', 'Scored 1 goal, 1 assist', 'N'),
(23, 43, '2024-03-15', 'Scored 1 goal', 'Y'), -- 'Injured' -> 'Y'
(24, 44, '2024-04-05', 'Scored 3 goals', 'N'),
(25, 45, '2024-05-12', '2 assists', 'N');

-- MatchEvent
INSERT INTO MatchEvent (MatchEventID, EventType, EventTime, PlayerID, MatchID, ImpactFantasyPoint)
VALUES
-- Football Events
(1, 'Touchdown', '15:30:00', 1, 1, 10),
(2, 'Touchdown', '15:20:00', 2, 1, 10),
(3, 'Interception', '15:45:00', 3, 1, -5),
(4, 'Sack', '15:55:00', 4, 1, 4),
(5, 'Rushing TD', '09:20:00', 5, 2, 8),
(6, 'Reception', '09:25:00', 6, 2, 5),
(7, 'Rushing TD', '09:30:00', 7, 2, 8),
(8, 'Reception', '14:10:00', 8, 3, 5),
(9, 'Rushing TD', '14:40:00', 9, 3, 8),
(10, 'Reception', '14:50:00', 10, 3, 5),

-- Basketball Events
(11, '3-Point Shot', '05:50:00', 21, 4, 8),
(12, 'Rebound', '05:20:00', 22, 4, 2),
(13, 'Assist', '05:15:00', 23, 4, 4),
(14, 'Block', '12:45:00', 24, 5, 3),
(15, 'Steal', '12:30:00', 25, 5, 4),
(16, 'Free Throw', '12:10:00', 26, 5, 1),
(17, '3-Point Shot', '12:40:00', 27, 5, 8),
(18, 'Assist', '15:20:00', 28, 6, 4),
(19, 'Rebound', '01:50:00', 29, 7, 2),
(20, 'Steal', '01:30:00', 30, 7, 3),

-- Soccer Events
(21, 'Goal', '10:15:00', 41, 11, 10),
(22, 'Assist', '10:00:00', 42, 11, 5),
(23, 'Goal', '11:45:00', 43, 12, 10),
(24, 'Yellow Card', '11:20:00', 44, 12, -2),
(25, 'Goal', '11:10:00', 45, 12, 10);

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
(12, '2024-04-22'),
(13, '2024-05-02'),
(14, '2024-05-12'),
(15, '2024-05-18'),
(16, '2024-05-25'),
(17, '2024-06-01'),
(18, '2024-06-10'),
(19, '2024-06-15'),
(20, '2024-06-25'),
(21, '2024-07-05'),
(22, '2024-07-15'),
(23, '2024-07-25'),
(24, '2024-08-01'),
(25, '2024-08-10');


-- PlayerTrade
INSERT INTO PlayerTrade (TradeID, PlayerID, FromOrTo)
VALUES
(1, 1, 'From'), (1, 2, 'To'),
(2, 3, 'From'), (2, 4, 'To'),
(3, 5, 'From'), (3, 6, 'To'),
(4, 7, 'From'), (4, 8, 'To'),
(5, 9, 'From'), (5, 10, 'To'),

(11, 21, 'From'), (11, 22, 'To'),
(12, 23, 'From'), (12, 24, 'To'),
(13, 25, 'From'), (13, 26, 'To'),
(14, 27, 'From'), (14, 28, 'To'),
(15, 29, 'From'), (15, 30, 'To'),

(21, 41, 'From'), (21, 42, 'To'),
(22, 43, 'From'), (22, 44, 'To'),
(23, 45, 'From'), (23, 46, 'To'),
(24, 47, 'From'), (24, 48, 'To'),
(25, 49, 'From'), (25, 50, 'To');



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
(1, 'P', '2024-01-05', 1, 1),
(2, 'A', '2024-01-10', 1, 2),
(3, 'D', '2024-01-15', 2, 3),
(4, 'A', '2024-01-20', 2, 4),
(5, 'P', '2024-01-25', 3, 5),
(6, 'D', '2024-02-01', 3, 6),
(7, 'A', '2024-02-05', 4, 7),
(8, 'P', '2024-02-10', 4, 8),
(9, 'A', '2024-02-15', 5, 9),
(10, 'D', '2024-02-20', 5, 10),
(11, 'P', '2024-02-25', 6, 11);










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