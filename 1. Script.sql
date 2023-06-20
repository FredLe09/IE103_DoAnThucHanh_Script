USE MASTER
GO

-------- CREATE DATABASE --------
DROP DATABASE IF EXISTS IE103_THUCHANH
GO

CREATE DATABASE IE103_THUCHANH
GO

USE IE103_THUCHANH
GO

CREATE TABLE KHACHHANG
(
	MAKH INT NOT NULL,
	TENKH VARCHAR(255) NOT NULL,
	SDT VARCHAR(10) NOT NULL,
	QUOCTICH VARCHAR(255) NOT NULL
)

CREATE TABLE LOAISP
(
	MALSP INT NOT NULL,
	TENLSP VARCHAR(255) NOT NULL,
	MOTA VARCHAR(255)
)

CREATE TABLE NHANVIEN
(
	MANV INT NOT NULL,
	TENNV VARCHAR(255) NOT NULL,
	SDT VARCHAR(10) NOT NULL,
	NGSINH SMALLDATETIME NOT NULL
)

CREATE TABLE NHACUNGCAP
(
	MANCC INT NOT NULL,
	TENNCC VARCHAR(255) NOT NULL,
	SDT VARCHAR(10) NOT NULL,
	THANHPHO VARCHAR(255),
	QUOCGIA VARCHAR(255)
)

CREATE TABLE SANPHAM
(
	MASP INT NOT NULL,
	TENSP VARCHAR(255) NOT NULL,
	MANCC INT NOT NULL,
	MALSP INT NOT NULL,
	GIA INT NOT NULL,
	SLTONKHO INT NOT NULL
)
CREATE TABLE HOADON
(
	MAHD INT NOT NULL,
	NGHD SMALLDATETIME NOT NULL,
	MAKH INT NOT NULL,
	MANV INT NOT NULL,
	THANHTIEN INT NOT NULL
)

CREATE TABLE CTHD
(
	MAHD INT NOT NULL,
	MASP INT NOT NULL,
	SL INT NOT NULL
)
GO

-- RANG BUOC TOAN VEN --
-- Rang buoc Khoa chinh
ALTER TABLE KHACHHANG
	ADD CONSTRAINT PK_KHACHHANG PRIMARY KEY (MAKH)

ALTER TABLE LOAISP
	ADD CONSTRAINT PK_LOAISP PRIMARY KEY (MALSP)

ALTER TABLE NHANVIEN
	ADD CONSTRAINT PK_NHANVIEN PRIMARY KEY (MANV)

ALTER TABLE NHACUNGCAP
	ADD CONSTRAINT PK_NCC PRIMARY KEY (MANCC)

ALTER TABLE SANPHAM
	ADD CONSTRAINT PK_SP PRIMARY KEY (MASP)

ALTER TABLE HOADON
	ADD CONSTRAINT PK_HD PRIMARY KEY (MAHD)

ALTER TABLE CTHD
	ADD CONSTRAINT PK_CTHD PRIMARY KEY (MAHD, MASP)

-- Rang buoc khoa ngoai
ALTER TABLE SANPHAM
	ADD CONSTRAINT FK_SP_NCC FOREIGN KEY (MANCC)
		REFERENCES NHACUNGCAP

ALTER TABLE SANPHAM
	ADD CONSTRAINT FK_SP_LSP FOREIGN KEY (MALSP)
		REFERENCES LOAISP

ALTER TABLE HOADON
	ADD CONSTRAINT FK_HD_KH FOREIGN KEY (MAKH)
		REFERENCES KHACHHANG

ALTER TABLE HOADON 
	ADD CONSTRAINT FK_HD_NV FOREIGN KEY (MANV)
		REFERENCES NHANVIEN

ALTER TABLE CTHD
	ADD CONSTRAINT FK_CTHD_HD FOREIGN KEY (MAHD)
		REFERENCES HOADON

ALTER TABLE CTHD
	ADD CONSTRAINT FK_CTHD_SP FOREIGN KEY (MASP)
		REFERENCES SANPHAM

-- Rang buoc DEFAULT, CHECK
ALTER TABLE SANPHAM
	ADD CONSTRAINT CHK_SLTONKHO CHECK (SLTONKHO >= 0)

ALTER TABLE HOADON
	ADD CONSTRAINT CHK_THANHTIEN CHECK (THANHTIEN >= 0)

ALTER TABLE HOADON
	ADD CONSTRAINT DF_THANHTIEN
	DEFAULT 0 FOR THANHTIEN
GO

-------- Import, Export, Backup, Restore --------
USE IE103_THUCHANH
GO

BACKUP DATABASE IE103_THUCHANH
	TO DISK = 'D:\IE103_THUCHANH.BAK'

RESTORE DATABASE IE103_THUCHANH
	FROM DISK = 'D:\IE103_THUCHANH.BAK'
GO

-------- USER, ROLE PHAN QUYEN --------
CREATE LOGIN khachhang WITH PASSWORD = '12345678';
CREATE USER khachhang FOR LOGIN khachhang;
CREATE LOGIN nhanvien WITH PASSWORD = '12345678';
CREATE USER nhanvien FOR LOGIN nhanvien;
CREATE LOGIN quanly WITH PASSWORD = '12345678';
CREATE USER quanly FOR LOGIN quanly;

CREATE ROLE KH;
CREATE ROLE NV;
CREATE ROLE QL;

ALTER ROLE KH ADD MEMBER khachhang;
ALTER ROLE NV ADD MEMBER nhanvien;
ALTER ROLE QL ADD MEMBER quanly;

GRANT SELECT ON SANPHAM TO KH;

GRANT SELECT, INSERT, UPDATE ON SANPHAM TO NV;
GRANT SELECT, INSERT, UPDATE ON LOAISP TO NV;
GRANT SELECT, INSERT, UPDATE ON HOADON TO NV;
GRANT SELECT, INSERT, UPDATE ON CTHD TO NV;
GRANT SELECT, INSERT, UPDATE ON KHACHHANG TO NV;

GRANT SELECT, INSERT, UPDATE, DELETE ON SANPHAM TO QL;
GRANT SELECT, INSERT, UPDATE, DELETE ON LOAISP TO QL;
GRANT SELECT, INSERT, UPDATE, DELETE ON NHACUNGCAP TO QL;
GRANT SELECT, INSERT, UPDATE, DELETE ON HOADON TO QL;
GRANT SELECT, INSERT, UPDATE, DELETE ON CTHD TO QL;
GRANT SELECT, INSERT, UPDATE, DELETE ON KHACHHANG TO QL;
GRANT SELECT, INSERT, UPDATE, DELETE ON NHANVIEN TO QL;

-------- STORE PROCEDURE --------
USE IE103_THUCHANH
GO

DROP PROCEDURE IF EXISTS PRINT_ALL_KHACHHANG
GO

-- PRINT ALL KHACHHANG WITH QUOCTICH
CREATE PROCEDURE PRINT_ALL_KHACHHANG (
	@QUOCTICH VARCHAR(255)
)
AS
BEGIN
	SELECT *
	FROM KHACHHANG
	WHERE QUOCTICH = @QUOCTICH
END
GO

EXEC PRINT_ALL_KHACHHANG 'Viet Nam'
GO

DROP PROCEDURE IF EXISTS PRINT_HOADON_KHACHHANG
GO

-- PRINT ALL HOADON OF KHACHHANG WITH SPECIFIC KHACHHANG_ID
CREATE PROCEDURE PRINT_HOADON_KHACHHANG (
	@KHACHHANG_ID INT
)
AS
BEGIN
	SELECT HD.MAHD, SP.TENSP, CTHD.SL, HD.NGHD
	FROM HOADON HD
		INNER JOIN CTHD
		ON HD.MAHD = CTHD.MAHD
		INNER JOIN SANPHAM SP
		ON CTHD.MASP = SP.MASP
	WHERE HD.MAKH = @KHACHHANG_ID
END
GO

EXEC PRINT_HOADON_KHACHHANG 100
GO

-------- TRIGGER --------
USE IE103_THUCHANH
GO

-- MAKE SURE WHEN INSERT HOADON
-- THANHTIEN EQUAL 0
--          | INS | DEL | UPD
-- HOADON   |  +  |  -  |  -

DROP TRIGGER IF EXISTS TRG_UPD_THANHTIEN_INS_HD
GO

CREATE TRIGGER TRG_UPD_THANHTIEN_INS_HD
ON HOADON 
AFTER INSERT 
AS 
BEGIN
	DECLARE @MAHD INT

	SELECT @MAHD = MAHD
	FROM inserted

	UPDATE HOADON
	SET THANHTIEN = 0
	WHERE MAHD = @MAHD
END
GO

-- MAKE SURE THANH TIEN IN HOADON IS ALWAYS
-- EQUAL SUM OF GIA IN SANPHAM OF CTHD
--          | INS | DEL | UPD
-- HOADON   |  -  |  -  |  + (THANHTIEN)
-- CTHD     |  +  |  +  |  + (MASP, SL)
-- SANPHAM  |  -  |  -  |  + (GIA)

DROP TRIGGER IF EXISTS TRG_UPD_THANHTIEN_UPD_HD
GO

CREATE TRIGGER TRG_UPD_THANHTIEN_UPD_HD
ON HOADON
AFTER UPDATE
AS
BEGIN
	IF UPDATE(THANHTIEN)
	BEGIN
		DECLARE @THANHTIEN INT
		DECLARE @MAHD INT
		DECLARE @THANHTIEN_REAL INT

		SELECT @MAHD = MAHD, @THANHTIEN = THANHTIEN
		FROM INSERTED

		SELECT @THANHTIEN_REAL = ISNULL(SUM(ISNULL(GIA, 0) * ISNULL(SL, 0)), 0)
		FROM SANPHAM SP
			INNER JOIN CTHD
			ON CTHD.MASP = SP.MASP
		WHERE CTHD.MAHD = @MAHD

		IF @THANHTIEN != @THANHTIEN_REAL
		BEGIN
			PRINT('CAN NOT UPDATE THANHTIEN WITH THIS VALUE!!!')
			ROLLBACK TRANSACTION
		END

	END
END
GO

DROP TRIGGER IF EXISTS TRG_UPD_THANHTIEN_ALL_CTHD
GO

CREATE TRIGGER TRG_UPD_THANHTIEN_ALL_CTHD
ON CTHD
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @MAHD INT
	DECLARE @TONG_TIEN INT

	SELECT @MAHD = T1.MAHD
	FROM (
		SELECT * FROM INSERTED
		UNION
		SELECT * FROM DELETED
	) T1

	SELECT @TONG_TIEN = ISNULL(SUM(ISNULL(SL, 0) * ISNULL(Gia, 0)), 0)
	FROM CTHD
	INNER JOIN SANPHAM SP
		ON CTHD.MASP = SP.MASP
	WHERE CTHD.MAHD = @MAHD

	UPDATE HOADON
	SET THANHTIEN = @TONG_TIEN
	WHERE MAHD = @MAHD
END
GO

DROP TRIGGER TRG_UPD_THANHTIEN_UPD_SP
GO

CREATE TRIGGER TRG_UPD_THANHTIEN_UPD_SP
ON SANPHAM
AFTER UPDATE
AS
BEGIN
	IF UPDATE(GIA)
	BEGIN
		DECLARE @MASP INT
		DECLARE @GIA INT

		DECLARE CURSOR_INSERTED CURSOR FOR
		SELECT MASP, GIA
		FROM INSERTED

		FETCH NEXT FROM CURSOR_INSERTED 
		INTO @MASP, @GIA

		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE HOADON
			SET THANHTIEN = THANHTIEN + @GIA * (
				SELECT SL
				FROM CTHD
				WHERE MAHD = HOADON.MAHD
					AND MASP = @MASP
			)
			WHERE MAHD IN (
				SELECT DISTINCT MAHD
				FROM CTHD
				WHERE MASP = @MASP
			)

			FETCH NEXT FROM CURSOR_INSERTED
			INTO @MASP, @GIA
		END

		CLOSE CURSOR_INSERTED
		DEALLOCATE CURSOR_INSERTED

		DECLARE CURSOR_DELETED CURSOR FOR
		SELECT MASP, GIA
		FROM DELETED

		FETCH NEXT FROM CURSOR_DELETED 
		INTO @MASP, @GIA

		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE HOADON
			SET THANHTIEN = THANHTIEN - @GIA * (
				SELECT SL
				FROM CTHD
				WHERE MAHD = HOADON.MAHD
					AND MASP = @MASP
			)
			WHERE MAHD IN (
				SELECT DISTINCT MAHD
				FROM CTHD
				WHERE MASP = @MASP
			)

			FETCH NEXT FROM CURSOR_DELETED
			INTO @MASP, @GIA
		END

		CLOSE CURSOR_DELETED
		DEALLOCATE CURSOR_DELETED
	END
END
GO

--MAKE SURE SLTONKHO DAP UNG DUOC HOA DON
--		  | INS | DEL | UPD 
--CTHD	  |  +  |  +  |  +  (MASP, SL)

DROP TRIGGER IF EXISTS TRG_UPD_SLTONKHO_ALL_CTHD
GO

CREATE TRIGGER TRG_UPD_SLTONKHO_ALL_CTHD
ON CTHD
AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	DECLARE @MASP INT
	DECLARE @SL_IN INT
	DECLARE @SL_OUT INT

	DECLARE CURSOR_INSERTED CURSOR FOR
	SELECT MASP, SL
	FROM INSERTED

	OPEN CURSOR_INSERTED
	FETCH NEXT FROM CURSOR_INSERTED
	INTO @MASP, @SL_OUT

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE SANPHAM
		SET SLTONKHO = SLTONKHO - @SL_OUT
		WHERE MASP = @MASP

		FETCH NEXT FROM CURSOR_INSERTED
		INTO @MASP, @SL_OUT
	END

	CLOSE CURSOR_INSERTED
	DEALLOCATE CURSOR_INSERTED

	DECLARE CURSOR_DELETED CURSOR FOR
	SELECT MASP, SL
	FROM DELETED

	OPEN CURSOR_DELETED
	FETCH NEXT FROM CURSOR_DELETED
	INTO @MASP, @SL_IN

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE SANPHAM
		SET SLTONKHO = SLTONKHO + @SL_IN
		WHERE MASP = @MASP

		FETCH NEXT FROM CURSOR_DELETED
		INTO @MASP, @SL_IN
	END

	CLOSE CURSOR_DELETED
	DEALLOCATE CURSOR_DELETED
END
GO

INSERT INTO KHACHHANG
VALUES
	(101, 'Mr Incredible', '0333333333', 'Viet Nam');
INSERT INTO NHANVIEN
VALUES
	(21, 'Le Trung Hieu', '0444444444', '4/4/2002');
INSERT INTO NHACUNGCAP
VALUES
	(11, 'Me Kong', '0555555555', NULL, NULL);
INSERT INTO LOAISP
VALUES
	(6, 'Phan bon', NULL);
INSERT INTO SANPHAM
VALUES
	(51, 'Sach Nham mat thay mua he', 11, 6, 200000, 100);
INSERT INTO SANPHAM
VALUES
	(52, '', 11, 6, 10000, 1000);
INSERT INTO HOADON
	(MAHD, NGHD, MAKH, MANV)
VALUES
	(201, '20230611', 101, 21);

DELETE FROM SANPHAM

DELETE FROM CTHD

INSERT INTO CTHD
VALUES
	(201, 51, 3)
INSERT INTO CTHD
VALUES
	(201, 52, 10)

UPDATE CTHD
SET MASP = 52
WHERE MAHD = 201
	AND MASP = 51

SELECT *
FROM KHACHHANG
SELECT *
FROM NHANVIEN
SELECT *
FROM NHACUNGCAP
SELECT *
FROM LOAISP
SELECT *
FROM SANPHAM
SELECT *
FROM HOADON
SELECT *
FROM CTHD

SELECT *
FROM SANPHAM

SELECT *
FROM HOADON
ORDER BY MAHD DESC

INSERT INTO CTHD
VALUES
	(201, 1, 3)

DELETE FROM CTHD
WHERE MAHD = 201

UPDATE CTHD
SET SL = 10
WHERE MAHD = 201

DELETE FROM HOADON
WHERE MAHD = 201

SELECT *
FROM CTHD
ORDER BY MAHD DESC

SELECT *
FROM SANPHAM

SELECT *
FROM HOADON

GO

SELECT *
FROM HOADON
GO

-------- VIEW --------
DROP VIEW IF EXISTS KHACHHANG_DOANHSO
GO

CREATE VIEW KHACHHANG_DOANHSO
AS
	SELECT TOP 10
		KH.MAKH, TENKH, SUM(THANHTIEN) AS DOANHSO
	FROM KHACHHANG KH
		INNER JOIN HOADON HD
		ON KH.MAKH = HD.MAKH
	GROUP BY KH.MAKH, TENKH
	ORDER BY DOANHSO DESC
GO

SELECT *
FROM KHACHHANG_DOANHSO
GO

SELECT *
FROM SANPHAM
GO

CREATE VIEW DOANHTHU_SP_VIEW
AS
	SELECT SP.MASP, SP.TENSP,
		SUM(CASE WHEN YEAR(NGHD) = 2020
				THEN SL * GIA
				ELSE 0
			END) AS DOANHTHU_2020,
		SUM(CASE WHEN YEAR(NGHD) = 2021
				THEN SL * GIA
				ELSE 0
			END) AS DOANHTHU_2021,
		SUM(CASE WHEN YEAR(NGHD) = 2022
				THEN SL * GIA
				ELSE 0
			END) AS DOANHTHU_2022,
		SUM(CASE WHEN YEAR(NGHD) IN (2020, 2021, 2022)
				THEN SL * GIA
				ELSE 0
			END) AS [TONGDOANHTHU_2020->2022]
	FROM SANPHAM SP
		LEFT JOIN CTHD
		ON SP.MASP = CTHD.MASP
		LEFT JOIN HOADON HD
		ON CTHD.MAHD = HD.MAHD
	WHERE YEAR(NGHD) IN (2020, 2021, 2022)
		OR NGHD IS NULL
	GROUP BY SP.MASP, SP.TENSP
	ORDER BY [TONGDOANHTHU_2020->2022] DESC OFFSET 0 ROWS
GO