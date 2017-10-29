--USE [master];
--CREATE DATABASE Forum;
--GO
--USE Forum2017SQL;

----DROP DATABASE Forum2017SQL;

DROP TRIGGER EditCookie;
DROP TRIGGER NewNotificationForReplyMessage;
DROP TRIGGER NewNotificationForMessage;

DROP FUNCTION IsAlreadyTakenNickname;
DROP FUNCTION IsAlreadyTakenLogin;
DROP FUNCTION GetUserId;

DROP PROCEDURE EditingMessage;
DROP PROCEDURE ReplyMessage;
DROP PROCEDURE NewMessage;
DROP PROCEDURE Registration;
DROP PROCEDURE SetCookie;
DROP PROCEDURE NewForum;

DROP TABLE Notifications;
DROP TABLE EditedMessage;
DROP TABLE RepliedMessage;
DROP TABLE [Message];
DROP TABLE [Forum];
DROP TABLE Cookie;
DROP TABLE Users;
GO

CREATE TABLE [Users]
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	[Login] NVARCHAR(50) NOT NULL UNIQUE,
	Avatar NVARCHAR(MAX),
	Nickname NVARCHAR(50) NOT NULL,
	[Password] VARBINARY(MAX) NOT NULL,
	Salt NVARCHAR(MAX),
	DateCreated DATETIME DEFAULT GETDATE() NOT NULL
)

CREATE TABLE Cookie
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	[UserId] BIGINT NOT NULL,-- FOREIGN KEY ([User]) REFERENCES dbo.Users(Id),
	IPv4 NVARCHAR(20) NOT NULL,
	SecretKey VARBINARY(MAX) NOT NULL,
	DateOfExpiry DATE DEFAULT GETDATE() NOT NULL,
	CONSTRAINT FK_User_Cookie FOREIGN KEY ([UserId]) REFERENCES dbo.Users(Id) ON DELETE CASCADE ON UPDATE CASCADE,
)

CREATE TABLE [Forum]
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	CodeForum NVARCHAR(MAX) NOT NULL,-- UNIQUE,
	Topic NVARCHAR(MAX) NOT NULL,
	Author BIGINT NOT NULL,-- FOREIGN KEY (UserСreated) REFERENCES dbo.Users(Id),
	DateCreated DATETIME DEFAULT GETDATE() NOT NULL,
	CONSTRAINT FK_Author_Forum FOREIGN KEY (Author) REFERENCES dbo.Users(Id) ON DELETE CASCADE ON UPDATE CASCADE,
)

CREATE TABLE [Message]
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	ForumId BIGINT NOT NULL,-- FOREIGN KEY (ForumId) REFERENCES dbo.Forum(Id),
	[UserId] BIGINT NOT NULL,-- FOREIGN KEY ([User]) REFERENCES dbo.Users(Id),
	[Message] NTEXT NOT NULL,
	DateCreated DATETIME DEFAULT GETDATE() NOT NULL,
	CONSTRAINT FK_ForumId_Message FOREIGN KEY (ForumId) REFERENCES dbo.Forum(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_User_Message FOREIGN KEY ([UserId]) REFERENCES dbo.Users(Id) ON UPDATE NO ACTION,
)

CREATE TABLE RepliedMessage
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	[UserId] BIGINT NOT NULL,-- FOREIGN KEY ([User]) REFERENCES dbo.Users(Id),
	MessageId BIGINT,-- FOREIGN KEY (MessageId) REFERENCES dbo.Message(Id),
	RepliedMessageId BIGINT,-- FOREIGN KEY (RepliedMessageId) REFERENCES dbo.RepliedMessage(Id),
	[Message] NTEXT,
	DateCreated DATETIME DEFAULT GETDATE() NOT NULL,
	CONSTRAINT FK_MessageId_RepliedMessage FOREIGN KEY (MessageId) REFERENCES dbo.[Message](Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_RepliedMessageId_RepliedMessage FOREIGN KEY (RepliedMessageId) REFERENCES dbo.RepliedMessage(Id) ON UPDATE NO ACTION,
	CONSTRAINT FK_User_RepliedMessage FOREIGN KEY ([UserId]) REFERENCES dbo.Users(Id) ON UPDATE NO ACTION,
)

CREATE TABLE EditedMessage
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	MessageId BIGINT,-- FOREIGN KEY (MessageId) REFERENCES dbo.Message(Id),
	RepliedMessageId BIGINT,-- FOREIGN KEY (RepliedMessageId) REFERENCES dbo.RepliedMessage(Id),
	[Message] NTEXT NOT NULL,
	DateCreated DATETIME NOT NULL,
	CONSTRAINT FK_MessageId_EditedMessage FOREIGN KEY (MessageId) REFERENCES dbo.[Message](Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_RepliedMessageId_EditedMessage FOREIGN KEY (RepliedMessageId) REFERENCES dbo.RepliedMessage(Id) ON UPDATE NO ACTION,
)

CREATE TABLE Notifications
(
	Id BIGINT IDENTITY PRIMARY KEY NOT NULL,
	MessageId BIGINT,-- FOREIGN KEY (MessageId) REFERENCES dbo.Message(Id),
	RepliedMessageId BIGINT,-- FOREIGN KEY (RepliedMessageId) REFERENCES dbo.RepliedMessage(Id),
	CONSTRAINT FK_MessageId_Notifications FOREIGN KEY (MessageId) REFERENCES dbo.[Message](Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_RepliedMessageId_Notifications FOREIGN KEY (RepliedMessageId) REFERENCES dbo.RepliedMessage(Id) ON UPDATE NO ACTION,
);
GO

CREATE FUNCTION GetUserId (@nickname NVARCHAR(50))
RETURNS BIGINT
AS 
BEGIN
    DECLARE @UserId BIGINT;
	SET @UserId = (SELECT TOP 1 Id FROM dbo.Users WHERE Nickname = @nickname);
    RETURN @UserId;
END;
GO

CREATE FUNCTION IsAlreadyTakenLogin(@login NVARCHAR(50))
RETURNS BIT
AS
BEGIN
	DECLARE @count BIGINT;
	SET @count = (SELECT COUNT([Login]) FROM dbo.Users WHERE [Login] = @login);
	IF @count > 0
	BEGIN
		RETURN 1;
	END;
	ELSE
	BEGIN
		RETURN 0;
	END;
	RETURN NULL;
END;
GO

CREATE FUNCTION IsAlreadyTakenNickname(@nickname NVARCHAR(50))
RETURNS BIT
AS
BEGIN
	DECLARE @count BIGINT;
	SET @count = (SELECT COUNT(Nickname) FROM dbo.Users WHERE Nickname = @nickname);
	IF @count > 0
	BEGIN
		RETURN 1;
	END;
	ELSE
	BEGIN
		RETURN 0;
	END;
	RETURN NULL;
END;
GO

CREATE PROCEDURE Registration
@login NVARCHAR(50),
@avatar NVARCHAR(MAX),
@nickname NVARCHAR(50),
@password VARBINARY(MAX),
@salt NVARCHAR(MAX),
@dateCreated DATETIME
AS
DECLARE @countLogin BIGINT;
DECLARE @countNickname BIGINT;
BEGIN
	SET @countLogin = (SELECT COUNT([Login]) FROM dbo.Users WHERE [Login] = @login);
	SET @countNickname = (SELECT COUNT(Nickname) FROM dbo.Users WHERE Nickname = @nickname);
	IF @countLogin = 0 AND @countNickname = 0
	BEGIN
		INSERT INTO dbo.Users
		        ( [Login] ,
		          Avatar ,
		          Nickname ,
		          [Password] ,
				  Salt,
		          DateCreated
		        )
		VALUES  ( @login , -- Login - nvarchar(50)
		          @avatar , -- Avatar - nvarchar(max)
		          @nickname , -- Nickname - nvarchar(50)
		          @password , -- Password - varbinary(max)
				  @salt, -- Salt - nvarchar(max)
		          @dateCreated  -- DateCreated - datetime
		        );
	END;
END;
GO

CREATE PROCEDURE SetCookie
@Nickname NVARCHAR(50),
@ipv4 NVARCHAR(20),
@secretKey VARBINARY(MAX),
@dateOfExpiry DATETIME
AS
DECLARE @UserId BIGINT;
BEGIN
	SET @UserId = dbo.GetUserId(@Nickname);
	IF @UserId > 0
	BEGIN
		INSERT INTO dbo.Cookie
		        ( [UserId] ,
		          IPv4 ,
		          SecretKey ,
		          DateOfExpiry
		        )
		VALUES  ( @UserId , -- User - bigint
		          @ipv4 , -- IPv4 - nvarchar(20)
		          @secretKey , -- SecretKey - varbinary(max)
		          @dateOfExpiry  -- DateCreated - datetime
		        );
	END;
END;
GO

CREATE PROCEDURE NewForum
@codeForum NVARCHAR(MAX),
@topic NVARCHAR(MAX),
@author NVARCHAR(50),
@dateCreated DATETIME
AS
DECLARE @AuthorId BIGINT;
BEGIN
	SET @AuthorId = dbo.GetUserId(@author);
	IF @AuthorId > 0
	BEGIN
		INSERT INTO dbo.[Forum]
		        ( CodeForum, Topic, Author, DateCreated )
		VALUES  ( @codeForum, -- CodeForum - nvarchar(max)
				  @topic, -- Topic - nvarchar(max)
		          @AuthorId, -- Author - bigint
		          @dateCreated  -- DateCreated - datetime
		          );
	END;
END;
GO

CREATE PROCEDURE NewMessage
@forumId BIGINT,
@nickname NVARCHAR(50),
@message NTEXT,
@dateCreated DATETIME
AS
DECLARE @UserId BIGINT;
BEGIN
	SET @UserId = dbo.GetUserId(@nickname);
	IF @UserId > 0
	BEGIN
		INSERT INTO dbo.[Message]
				( ForumId ,
				  [UserId] ,
				  [Message] ,
				  DateCreated
				)
		VALUES  ( @forumId , -- ForumId - bigint
				  @UserId , -- User - bigint
				  @message , -- Message - text
				  @dateCreated  -- DateCreated - datetime
				);
	END;
END;
GO

CREATE PROCEDURE ReplyMessage
@nickname NVARCHAR(50),
@messageId BIGINT,
@replydMessageId BIGINT,
@message NTEXT,
@dateCreated DATETIME
AS
DECLARE @UserId BIGINT;
BEGIN
	SET @UserId = dbo.GetUserId(@nickname);
	IF @UserId > 0
	BEGIN
		INSERT INTO dbo.RepliedMessage
		        ( [UserId] ,
		          MessageId ,
		          RepliedMessageId ,
		          [Message] ,
		          DateCreated
		        )
		VALUES  ( @UserId , -- User - bigint
		          @messageId , -- MessageId - bigint
		          @replydMessageId , -- RepliedMessageId - bigint
		          @message , -- Message - text
		          @dateCreated  -- DateCreated - datetime
		        );
	END;
END;
GO

CREATE PROCEDURE EditingMessage
@messageId BIGINT,
@repliedMessageId BIGINT,
@message NTEXT,
@dateCreated DATETIME,
@messageOld NTEXT
AS
BEGIN
	IF @messageId > 0
	BEGIN
		SET @messageOld = (SELECT [Message] FROM dbo.[Message] WHERE Id = @messageId);
		UPDATE dbo.[Message] SET [Message] = @message WHERE Id = @messageId;
		INSERT INTO dbo.EditedMessage
		        ( MessageId ,
		          RepliedMessageId ,
		          [Message] ,
		          DateCreated
		        )
		VALUES  ( @messageId , -- MessageId - bigint
		          NULL , -- RepliedMessageId - bigint
		          @messageOld, -- Message - text
		          @dateCreated  -- DateCreated - datetime
		        );
	END;
	ELSE
	BEGIN
		IF @repliedMessageId > 0
		BEGIN
			SET @messageOld = (SELECT [Message] FROM dbo.RepliedMessage WHERE Id = @repliedMessageId);
			UPDATE dbo.RepliedMessage SET [Message] = @message WHERE Id = @repliedMessageId;
			INSERT INTO dbo.EditedMessage
			        ( MessageId ,
			          RepliedMessageId ,
			          [Message] ,
			          DateCreated
			        )
			VALUES  ( NULL , -- MessageId - bigint
			          @repliedMessageId , -- RepliedMessageId - bigint
			          @messageOld, -- Message - text
			          @dateCreated  -- DateCreated - datetime
			        );
		END;
	END;
END;
GO

CREATE TRIGGER NewNotificationForMessage ON dbo.[Message]
AFTER INSERT
AS
DECLARE @Id BIGINT;
BEGIN
	SET @Id = (SELECT TOP 1 Id FROM dbo.[Message] ORDER BY Id DESC);
	INSERT INTO dbo.Notifications
	        ( MessageId, RepliedMessageId )
	VALUES  ( @Id, -- MessageId - bigint
	          NULL  -- RepliedMessageId - bigint
	          )
END;
GO

CREATE TRIGGER NewNotificationForReplyMessage ON dbo.RepliedMessage
AFTER INSERT
AS
DECLARE @Id BIGINT;
BEGIN
	SET @Id = (SELECT TOP 1 Id FROM dbo.RepliedMessage ORDER BY Id DESC);
	INSERT INTO dbo.Notifications
	        ( MessageId, RepliedMessageId )
	VALUES  ( NULL, -- MessageId - bigint
	          @Id  -- RepliedMessageId - bigint
	          )
END;
GO
CREATE TRIGGER EditCookie ON dbo.Cookie
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DELETE FROM dbo.Cookie WHERE DateOfExpiry < GETDATE();
END;
GO

SELECT * FROM dbo.Notifications;
SELECT * FROM dbo.EditedMessage;
SELECT * FROM dbo.RepliedMessage;
SELECT * FROM dbo.[Message];
SELECT * FROM dbo.[Forum];
SELECT * FROM dbo.Cookie;
SELECT * FROM dbo.Users;
GO

--SELECT CONVERT(NVARCHAR(MAX),DATEADD(day, 31, getdate()))
--SELECT Id FROM dbo.Users WHERE Nickname = N'QWERT'
--SELECT DATEADD(day, -30, getdate());
--SELECT dbo.IsAlreadyTakenLogin('User');
--SELECT dbo.IsAlreadyTakenNickname('User');
--SELECT TOP 1 Id FROM dbo.Cookie WHERE DateCreated < DATEADD(day, -1, GETDATE())

--DELETE FROM dbo.Forum;