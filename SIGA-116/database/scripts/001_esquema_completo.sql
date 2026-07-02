-- ============================================================
-- SIGA-116
-- Sistema Inteligente de Gestión Académica y Control Biométrico
-- Institución Educativa Abraham Valdelomar N.° 116
-- 
-- Script: 001_esquema_completo.sql
-- Versión: 1.0
-- Motor: SQL Server 2022
-- Descripción: Creación completa de base de datos, esquemas,
--              tablas, relaciones, índices y datos iniciales.
-- ============================================================

-- ============================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SIGA116')
BEGIN
    CREATE DATABASE SIGA116;
END
GO

USE SIGA116;
GO

-- ============================================================
-- 2. CREACIÓN DE ESQUEMAS
-- ============================================================
CREATE SCHEMA IF NOT EXISTS security;
GO
CREATE SCHEMA IF NOT EXISTS institutional;
GO
CREATE SCHEMA IF NOT EXISTS academic;
GO
CREATE SCHEMA IF NOT EXISTS evaluation;
GO
CREATE SCHEMA IF NOT EXISTS attendance;
GO
CREATE SCHEMA IF NOT EXISTS communication;
GO
CREATE SCHEMA IF NOT EXISTS biometric;
GO
CREATE SCHEMA IF NOT EXISTS audit;
GO

-- ============================================================
-- 3. TABLAS - ESQUEMA security
-- ============================================================

-- 3.1. Permissions
CREATE TABLE security.Permissions (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(50)     NOT NULL,
    Name            VARCHAR(100)    NOT NULL,
    Description     NVARCHAR(255)   NULL,
    Module          VARCHAR(50)     NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_Permissions_Code UNIQUE (Code)
);
GO

-- 3.2. Roles (extiende IdentityRole)
CREATE TABLE security.Roles (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Name            VARCHAR(50)     NOT NULL,
    NormalizedName  VARCHAR(50)     NOT NULL,
    Description     NVARCHAR(255)   NULL,
    IsSystem        BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_Roles_Name UNIQUE (Name),
    CONSTRAINT UQ_Roles_NormalizedName UNIQUE (NormalizedName)
);
GO

-- 3.3. RolePermissions
CREATE TABLE security.RolePermissions (
    RoleId          INT             NOT NULL,
    PermissionId    INT             NOT NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_RolePermissions PRIMARY KEY (RoleId, PermissionId),
    CONSTRAINT FK_RolePermissions_Role FOREIGN KEY (RoleId) REFERENCES security.Roles(Id),
    CONSTRAINT FK_RolePermissions_Permission FOREIGN KEY (PermissionId) REFERENCES security.Permissions(Id)
);
GO

-- 3.4. Users (extiende IdentityUser con datos institucionales)
CREATE TABLE security.Users (
    Id                      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    UserName                VARCHAR(50)      NOT NULL,
    NormalizedUserName      VARCHAR(50)      NOT NULL,
    Email                   VARCHAR(100)     NULL,
    NormalizedEmail         VARCHAR(100)     NULL,
    EmailConfirmed          BIT              NOT NULL DEFAULT 0,
    PasswordHash            NVARCHAR(MAX)    NOT NULL,
    SecurityStamp           NVARCHAR(MAX)    NULL,
    ConcurrencyStamp        NVARCHAR(MAX)    NULL,
    PhoneNumber             VARCHAR(20)      NULL,
    PhoneNumberConfirmed    BIT              NOT NULL DEFAULT 0,
    TwoFactorEnabled        BIT              NOT NULL DEFAULT 0,
    LockoutEnd              DATETIMEOFFSET   NULL,
    LockoutEnabled          BIT              NOT NULL DEFAULT 1,
    AccessFailedCount       INT              NOT NULL DEFAULT 0,

    -- Campos personalizados institucionales
    FirstName               NVARCHAR(100)    NOT NULL,
    LastName                NVARCHAR(100)    NOT NULL,
    DocumentType            VARCHAR(5)       NOT NULL DEFAULT 'DNI',
    DocumentNumber          VARCHAR(20)      NOT NULL,
    PhotoUrl                NVARCHAR(500)    NULL,
    IsActive                BIT              NOT NULL DEFAULT 1,
    IsDeleted               BIT              NOT NULL DEFAULT 0,
    MustChangePassword      BIT              NOT NULL DEFAULT 0,
    LastLoginAt             DATETIME2        NULL,
    CreatedAt               DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt               DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Users PRIMARY KEY (Id),
    CONSTRAINT UQ_Users_UserName UNIQUE (UserName),
    CONSTRAINT UQ_Users_NormalizedUserName UNIQUE (NormalizedUserName),
    CONSTRAINT UQ_Users_DocumentNumber UNIQUE (DocumentType, DocumentNumber)
);
GO

CREATE INDEX IX_Users_Email ON security.Users(Email) WHERE Email IS NOT NULL;
CREATE INDEX IX_Users_IsActive ON security.Users(IsActive) WHERE IsActive = 1;
GO

-- 3.5. UserRoles
CREATE TABLE security.UserRoles (
    UserId          UNIQUEIDENTIFIER NOT NULL,
    RoleId          INT              NOT NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_UserRoles_User FOREIGN KEY (UserId) REFERENCES security.Users(Id),
    CONSTRAINT FK_UserRoles_Role FOREIGN KEY (RoleId) REFERENCES security.Roles(Id)
);
GO

-- 3.6. UserClaims
CREATE TABLE security.UserClaims (
    Id              INT              IDENTITY(1,1) PRIMARY KEY,
    UserId          UNIQUEIDENTIFIER NOT NULL,
    ClaimType       NVARCHAR(255)    NOT NULL,
    ClaimValue      NVARCHAR(MAX)    NOT NULL,

    CONSTRAINT FK_UserClaims_User FOREIGN KEY (UserId) REFERENCES security.Users(Id)
);
GO

CREATE INDEX IX_UserClaims_UserId ON security.UserClaims(UserId);
GO

-- 3.7. UserLogins
CREATE TABLE security.UserLogins (
    LoginProvider       NVARCHAR(128)    NOT NULL,
    ProviderKey         NVARCHAR(128)    NOT NULL,
    ProviderDisplayName NVARCHAR(255)    NULL,
    UserId              UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT PK_UserLogins PRIMARY KEY (LoginProvider, ProviderKey),
    CONSTRAINT FK_UserLogins_User FOREIGN KEY (UserId) REFERENCES security.Users(Id)
);
GO

CREATE INDEX IX_UserLogins_UserId ON security.UserLogins(UserId);
GO

-- 3.8. UserTokens
CREATE TABLE security.UserTokens (
    UserId          UNIQUEIDENTIFIER NOT NULL,
    LoginProvider   NVARCHAR(128)    NOT NULL,
    Name            NVARCHAR(128)    NOT NULL,
    Value           NVARCHAR(MAX)    NULL,

    CONSTRAINT PK_UserTokens PRIMARY KEY (UserId, LoginProvider, Name),
    CONSTRAINT FK_UserTokens_User FOREIGN KEY (UserId) REFERENCES security.Users(Id)
);
GO

-- 3.9. UserSessions
CREATE TABLE security.UserSessions (
    Id                  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    UserId              UNIQUEIDENTIFIER NOT NULL,
    AccessToken         NVARCHAR(MAX)    NOT NULL,
    RefreshToken        NVARCHAR(MAX)    NOT NULL,
    AccessTokenExpires  DATETIME2        NOT NULL,
    RefreshTokenExpires DATETIME2        NOT NULL,
    CreatedAt           DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    RevokedAt           DATETIME2        NULL,
    IpAddress           VARCHAR(45)      NOT NULL,
    UserAgent           NVARCHAR(500)    NULL,
    IsRevoked           AS CASE WHEN RevokedAt IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,

    CONSTRAINT PK_UserSessions PRIMARY KEY (Id),
    CONSTRAINT FK_UserSessions_User FOREIGN KEY (UserId) REFERENCES security.Users(Id)
);
GO

CREATE INDEX IX_UserSessions_UserId ON security.UserSessions(UserId);
CREATE INDEX IX_UserSessions_RefreshToken ON security.UserSessions(RefreshToken);
CREATE INDEX IX_UserSessions_Active ON security.UserSessions(UserId, RevokedAt) WHERE RevokedAt IS NULL;
GO

-- 3.10. LoginAttempts
CREATE TABLE security.LoginAttempts (
    Id              BIGINT           IDENTITY(1,1) PRIMARY KEY,
    UserId          UNIQUEIDENTIFIER NULL,
    Email           VARCHAR(100)     NULL,
    AttemptedAt     DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    Success         BIT              NOT NULL,
    IpAddress       VARCHAR(45)      NOT NULL,
    UserAgent       NVARCHAR(500)    NULL,
    FailureReason   VARCHAR(100)     NULL
);
GO

CREATE INDEX IX_LoginAttempts_Email ON security.LoginAttempts(Email, AttemptedAt);
CREATE INDEX IX_LoginAttempts_Ip ON security.LoginAttempts(IpAddress, AttemptedAt);
GO

-- ============================================================
-- 4. TABLAS - ESQUEMA institutional
-- ============================================================

-- 4.1. AcademicYear
CREATE TABLE institutional.AcademicYear (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Year            INT             NOT NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 0,
    IsClosed        BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_AcademicYear_Year UNIQUE (Year),
    CONSTRAINT CK_AcademicYear_Year CHECK (Year >= 2020 AND Year <= 2100),
    CONSTRAINT CK_AcademicYear_Dates CHECK (EndDate > StartDate)
);
GO

-- 4.2. AcademicPeriod
CREATE TABLE institutional.AcademicPeriod (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    AcademicYearId  INT             NOT NULL,
    Name            VARCHAR(50)     NOT NULL,
    ShortName       VARCHAR(10)     NOT NULL,
    PeriodNumber    INT             NOT NULL,
    StartDate       DATE            NOT NULL,
    EndDate         DATE            NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 0,

    CONSTRAINT FK_AcademicPeriod_Year FOREIGN KEY (AcademicYearId) REFERENCES institutional.AcademicYear(Id),
    CONSTRAINT CK_AcademicPeriod_Number CHECK (PeriodNumber BETWEEN 1 AND 4),
    CONSTRAINT CK_AcademicPeriod_Dates CHECK (EndDate > StartDate),
    CONSTRAINT UQ_AcademicPeriod_YearPeriod UNIQUE (AcademicYearId, PeriodNumber)
);
GO

-- 4.3. Institution
CREATE TABLE institutional.Institution (
    Id                  INT             NOT NULL DEFAULT 1,
    Name                NVARCHAR(200)   NOT NULL,
    ShortName           VARCHAR(50)     NULL,
    Ruc                 VARCHAR(11)     NOT NULL,
    Address             NVARCHAR(255)   NOT NULL,
    Phone               VARCHAR(20)     NULL,
    Email               VARCHAR(100)    NULL,
    Website             VARCHAR(200)    NULL,
    LogoUrl             NVARCHAR(500)   NULL,
    FaviconUrl          NVARCHAR(500)   NULL,
    PrimaryColor        VARCHAR(7)      NOT NULL DEFAULT '#1A73E8',
    SecondaryColor      VARCHAR(7)      NOT NULL DEFAULT '#34A853',
    AcademicYearActiveId INT            NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Institution PRIMARY KEY (Id),
    CONSTRAINT CK_Institution_Id CHECK (Id = 1),
    CONSTRAINT FK_Institution_AcademicYear FOREIGN KEY (AcademicYearActiveId) REFERENCES institutional.AcademicYear(Id)
);
GO

-- 4.4. NewsCategory
CREATE TABLE institutional.NewsCategory (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    Slug            VARCHAR(100)    NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_NewsCategory_Slug UNIQUE (Slug)
);
GO

-- 4.5. News
CREATE TABLE institutional.News (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Title           NVARCHAR(200)   NOT NULL,
    Slug            VARCHAR(200)    NOT NULL,
    Summary         NVARCHAR(500)   NULL,
    Content         NVARCHAR(MAX)   NOT NULL,
    ImageUrl        NVARCHAR(500)   NULL,
    CategoryId      INT             NULL,
    PublishedById   UNIQUEIDENTIFIER NULL,
    PublishedAt     DATETIME2       NULL,
    IsPublished     BIT             NOT NULL DEFAULT 0,
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_News_Slug UNIQUE (Slug),
    CONSTRAINT FK_News_Category FOREIGN KEY (CategoryId) REFERENCES institutional.NewsCategory(Id),
    CONSTRAINT FK_News_Publisher FOREIGN KEY (PublishedById) REFERENCES security.Users(Id)
);
GO

CREATE INDEX IX_News_Published ON institutional.News(IsPublished, PublishedAt) WHERE IsPublished = 1;
CREATE INDEX IX_News_Deleted ON institutional.News(IsDeleted) WHERE IsDeleted = 0;
GO

-- 4.6. Event
CREATE TABLE institutional.Event (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Title           NVARCHAR(200)   NOT NULL,
    Description     NVARCHAR(MAX)   NULL,
    EventDate       DATE            NOT NULL,
    StartTime       TIME            NULL,
    EndTime         TIME            NULL,
    Location        NVARCHAR(255)   NULL,
    ImageUrl        NVARCHAR(500)   NULL,
    IsPublished     BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX IX_Event_Date ON institutional.Event(EventDate);
CREATE INDEX IX_Event_Published ON institutional.Event(IsPublished, EventDate) WHERE IsPublished = 1;
GO

-- 4.7. GalleryAlbum
CREATE TABLE institutional.GalleryAlbum (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Title           NVARCHAR(200)   NOT NULL,
    Description     NVARCHAR(500)   NULL,
    CoverImageUrl   NVARCHAR(500)   NULL,
    IsPublished     BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- 4.8. GalleryMedia
CREATE TABLE institutional.GalleryMedia (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    AlbumId         INT             NOT NULL,
    MediaUrl        NVARCHAR(500)   NOT NULL,
    MediaType       VARCHAR(10)     NOT NULL,
    Caption         NVARCHAR(255)   NULL,
    SortOrder       INT             NOT NULL DEFAULT 0,
    UploadedAt      DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_GalleryMedia_Album FOREIGN KEY (AlbumId) REFERENCES institutional.GalleryAlbum(Id),
    CONSTRAINT CK_GalleryMedia_Type CHECK (MediaType IN ('Imagen', 'Video'))
);
GO

CREATE INDEX IX_GalleryMedia_Album ON institutional.GalleryMedia(AlbumId, SortOrder);
GO

-- 4.9. ContactMessage
CREATE TABLE institutional.ContactMessage (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(150)   NOT NULL,
    Email           VARCHAR(100)    NOT NULL,
    Phone           VARCHAR(20)     NULL,
    Subject         NVARCHAR(200)   NOT NULL,
    Message         NVARCHAR(MAX)   NOT NULL,
    IsRead          BIT             NOT NULL DEFAULT 0,
    ReadAt          DATETIME2       NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX IX_ContactMessage_Read ON institutional.ContactMessage(IsRead, CreatedAt);
GO

-- 4.10. SiteSetting
CREATE TABLE institutional.SiteSetting (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    [Key]           VARCHAR(100)    NOT NULL,
    Value           NVARCHAR(MAX)   NOT NULL,
    Description     NVARCHAR(255)   NULL,
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_SiteSetting_Key UNIQUE ([Key])
);
GO

-- ============================================================
-- 5. TABLAS - ESQUEMA academic
-- ============================================================

-- 5.1. EducationalLevel
CREATE TABLE academic.EducationalLevel (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(5)      NOT NULL,
    Name            NVARCHAR(50)    NOT NULL,
    SortOrder       INT             NOT NULL DEFAULT 0,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_EducationalLevel_Code UNIQUE (Code)
);
GO

-- 5.2. Grade
CREATE TABLE academic.Grade (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    EducationalLevelId  INT             NOT NULL,
    Code                VARCHAR(10)     NOT NULL,
    Name                NVARCHAR(50)    NOT NULL,
    SortOrder           INT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Grade_Level FOREIGN KEY (EducationalLevelId) REFERENCES academic.EducationalLevel(Id),
    CONSTRAINT UQ_Grade_Code UNIQUE (Code)
);
GO

CREATE INDEX IX_Grade_Level ON academic.Grade(EducationalLevelId, SortOrder);
GO

-- 5.3. Shift
CREATE TABLE academic.Shift (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(5)      NOT NULL,
    Name            NVARCHAR(50)    NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_Shift_Code UNIQUE (Code)
);
GO

-- 5.4. Section
CREATE TABLE academic.Section (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    GradeId         INT             NOT NULL,
    Code            VARCHAR(10)     NOT NULL,
    Name            NVARCHAR(50)    NOT NULL,
    Capacity        INT             NOT NULL DEFAULT 30,
    ShiftId         INT             NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Section_Grade FOREIGN KEY (GradeId) REFERENCES academic.Grade(Id),
    CONSTRAINT FK_Section_Shift FOREIGN KEY (ShiftId) REFERENCES academic.Shift(Id),
    CONSTRAINT CK_Section_Capacity CHECK (Capacity BETWEEN 1 AND 50),
    CONSTRAINT UQ_Section_Code UNIQUE (Code)
);
GO

CREATE INDEX IX_Section_Grade ON academic.Section(GradeId);
GO

-- 5.5. Classroom
CREATE TABLE academic.Classroom (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(20)     NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    Capacity        INT             NOT NULL DEFAULT 30,
    Location        NVARCHAR(100)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_Classroom_Code UNIQUE (Code),
    CONSTRAINT CK_Classroom_Capacity CHECK (Capacity > 0)
);
GO

-- 5.6. CurricularArea
CREATE TABLE academic.CurricularArea (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    Code                VARCHAR(10)     NOT NULL,
    Name                NVARCHAR(100)   NOT NULL,
    EducationalLevelId  INT             NOT NULL,
    SortOrder           INT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_CurricularArea_Level FOREIGN KEY (EducationalLevelId) REFERENCES academic.EducationalLevel(Id),
    CONSTRAINT UQ_CurricularArea_Code UNIQUE (Code)
);
GO

-- 5.7. Course
CREATE TABLE academic.Course (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    Code                VARCHAR(10)     NOT NULL,
    Name                NVARCHAR(150)   NOT NULL,
    CurricularAreaId    INT             NOT NULL,
    EducationalLevelId  INT             NOT NULL,
    HoursPerWeek        DECIMAL(4,1)    NOT NULL DEFAULT 2,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Course_Area FOREIGN KEY (CurricularAreaId) REFERENCES academic.CurricularArea(Id),
    CONSTRAINT FK_Course_Level FOREIGN KEY (EducationalLevelId) REFERENCES academic.EducationalLevel(Id),
    CONSTRAINT UQ_Course_Code UNIQUE (Code),
    CONSTRAINT CK_Course_Hours CHECK (HoursPerWeek > 0)
);
GO

CREATE INDEX IX_Course_Level ON academic.Course(EducationalLevelId);
CREATE INDEX IX_Course_Area ON academic.Course(CurricularAreaId);
GO

-- 5.8. Person
CREATE TABLE academic.Person (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    DocumentType    VARCHAR(5)      NOT NULL DEFAULT 'DNI',
    DocumentNumber  VARCHAR(20)     NOT NULL,
    FirstName       NVARCHAR(100)   NOT NULL,
    MiddleName      NVARCHAR(100)   NULL,
    LastName        NVARCHAR(100)   NOT NULL,
    SecondLastName  NVARCHAR(100)   NULL,
    DateOfBirth     DATE            NULL,
    Gender          VARCHAR(10)     NULL,
    Phone           VARCHAR(20)     NULL,
    Email           VARCHAR(100)    NULL,
    Address         NVARCHAR(255)   NULL,
    PhotoUrl        NVARCHAR(500)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    IsDeleted       BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_Person_Document UNIQUE (DocumentType, DocumentNumber),
    CONSTRAINT CK_Person_DocumentType CHECK (DocumentType IN ('DNI', 'CE', 'Pasaporte'))
);
GO

CREATE INDEX IX_Person_Name ON academic.Person(LastName, FirstName);
CREATE INDEX IX_Person_Active ON academic.Person(IsActive) WHERE IsActive = 1;
GO

-- 5.9. Student
CREATE TABLE academic.Student (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    PersonId            INT             NOT NULL,
    StudentCode         VARCHAR(20)     NOT NULL,
    EnrollmentDate      DATE            NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS DATE),
    MedicalNotes        NVARCHAR(500)   NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Student_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT UQ_Student_Code UNIQUE (StudentCode),
    CONSTRAINT UQ_Student_Person UNIQUE (PersonId)
);
GO

CREATE INDEX IX_Student_Active ON academic.Student(IsActive) WHERE IsActive = 1;
GO

-- 5.10. Teacher
CREATE TABLE academic.Teacher (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    PersonId            INT             NOT NULL,
    TeacherCode         VARCHAR(20)     NOT NULL,
    ProfessionalTitle   NVARCHAR(200)   NULL,
    Specialization      NVARCHAR(200)   NULL,
    HireDate            DATE            NOT NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Teacher_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT UQ_Teacher_Code UNIQUE (TeacherCode),
    CONSTRAINT UQ_Teacher_Person UNIQUE (PersonId)
);
GO

CREATE INDEX IX_Teacher_Active ON academic.Teacher(IsActive) WHERE IsActive = 1;
GO

-- 5.11. AdministrativeStaff
CREATE TABLE academic.AdministrativeStaff (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    PersonId            INT             NOT NULL,
    StaffCode           VARCHAR(20)     NOT NULL,
    Position            NVARCHAR(100)   NOT NULL,
    HireDate            DATE            NOT NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_AdminStaff_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT UQ_AdminStaff_Code UNIQUE (StaffCode),
    CONSTRAINT UQ_AdminStaff_Person UNIQUE (PersonId)
);
GO

-- 5.12. Parent
CREATE TABLE academic.Parent (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    PersonId        INT             NOT NULL,
    Occupation      NVARCHAR(100)   NULL,
    WorkPhone       VARCHAR(20)     NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Parent_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT UQ_Parent_Person UNIQUE (PersonId)
);
GO

-- 5.13. StudentParent
CREATE TABLE academic.StudentParent (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    StudentId           INT             NOT NULL,
    ParentId            INT             NOT NULL,
    RelationshipType    VARCHAR(20)     NOT NULL,
    IsPrimaryContact    BIT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_StudentParent_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_StudentParent_Parent FOREIGN KEY (ParentId) REFERENCES academic.Parent(Id),
    CONSTRAINT CK_StudentParent_Relationship CHECK (RelationshipType IN ('Padre', 'Madre', 'Tutor', 'Apoderado')),
    CONSTRAINT UQ_StudentParent UNIQUE (StudentId, ParentId)
);
GO

CREATE INDEX IX_StudentParent_Student ON academic.StudentParent(StudentId);
CREATE INDEX IX_StudentParent_Parent ON academic.StudentParent(ParentId);
GO

-- 5.14. UserPerson (vincula Identity User con Persona)
CREATE TABLE academic.UserPerson (
    UserId          UNIQUEIDENTIFIER NOT NULL,
    PersonId        INT              NOT NULL,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_UserPerson PRIMARY KEY (UserId, PersonId),
    CONSTRAINT FK_UserPerson_User FOREIGN KEY (UserId) REFERENCES security.Users(Id),
    CONSTRAINT FK_UserPerson_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id)
);
GO

-- 5.15. Enrollment
CREATE TABLE academic.Enrollment (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    StudentId           INT             NOT NULL,
    AcademicYearId      INT             NOT NULL,
    GradeId             INT             NOT NULL,
    SectionId           INT             NOT NULL,
    EnrollmentDate      DATE            NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS DATE),
    EnrollmentType      VARCHAR(20)     NOT NULL,
    Status              VARCHAR(20)     NOT NULL DEFAULT 'Activo',
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Enrollment_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_Enrollment_Year FOREIGN KEY (AcademicYearId) REFERENCES institutional.AcademicYear(Id),
    CONSTRAINT FK_Enrollment_Grade FOREIGN KEY (GradeId) REFERENCES academic.Grade(Id),
    CONSTRAINT FK_Enrollment_Section FOREIGN KEY (SectionId) REFERENCES academic.Section(Id),
    CONSTRAINT CK_Enrollment_Type CHECK (EnrollmentType IN ('Nueva', 'Renovacion', 'Traslado')),
    CONSTRAINT CK_Enrollment_Status CHECK (Status IN ('Activo', 'Retirado', 'Egresado')),
    CONSTRAINT UQ_Enrollment_StudentYear UNIQUE (StudentId, AcademicYearId)
);
GO

CREATE INDEX IX_Enrollment_Section ON academic.Enrollment(SectionId, AcademicYearId);
CREATE INDEX IX_Enrollment_Active ON academic.Enrollment(AcademicYearId, IsActive) WHERE IsActive = 1;
GO

-- 5.16. TeacherAssignment
CREATE TABLE academic.TeacherAssignment (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    TeacherId           INT             NOT NULL,
    CourseId            INT             NOT NULL,
    SectionId           INT             NOT NULL,
    AcademicYearId      INT             NOT NULL,
    IsPrincipal         BIT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_TeacherAssignment_Teacher FOREIGN KEY (TeacherId) REFERENCES academic.Teacher(Id),
    CONSTRAINT FK_TeacherAssignment_Course FOREIGN KEY (CourseId) REFERENCES academic.Course(Id),
    CONSTRAINT FK_TeacherAssignment_Section FOREIGN KEY (SectionId) REFERENCES academic.Section(Id),
    CONSTRAINT FK_TeacherAssignment_Year FOREIGN KEY (AcademicYearId) REFERENCES institutional.AcademicYear(Id),
    CONSTRAINT UQ_TeacherAssignment UNIQUE (TeacherId, CourseId, SectionId, AcademicYearId)
);
GO

CREATE INDEX IX_TeacherAssignment_Section ON academic.TeacherAssignment(SectionId, AcademicYearId);
CREATE INDEX IX_TeacherAssignment_Teacher ON academic.TeacherAssignment(TeacherId, AcademicYearId);
GO

-- 5.17. Schedule
CREATE TABLE academic.Schedule (
    Id                      INT             IDENTITY(1,1) PRIMARY KEY,
    SectionId               INT             NOT NULL,
    CourseId                INT             NOT NULL,
    TeacherAssignmentId     INT             NOT NULL,
    ClassroomId             INT             NOT NULL,
    DayOfWeek               INT             NOT NULL,
    StartTime               TIME            NOT NULL,
    EndTime                 TIME            NOT NULL,
    ShiftId                 INT             NOT NULL,
    AcademicYearId          INT             NOT NULL,
    IsActive                BIT             NOT NULL DEFAULT 1,
    CreatedAt               DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Schedule_Section FOREIGN KEY (SectionId) REFERENCES academic.Section(Id),
    CONSTRAINT FK_Schedule_Course FOREIGN KEY (CourseId) REFERENCES academic.Course(Id),
    CONSTRAINT FK_Schedule_Assignment FOREIGN KEY (TeacherAssignmentId) REFERENCES academic.TeacherAssignment(Id),
    CONSTRAINT FK_Schedule_Classroom FOREIGN KEY (ClassroomId) REFERENCES academic.Classroom(Id),
    CONSTRAINT FK_Schedule_Shift FOREIGN KEY (ShiftId) REFERENCES academic.Shift(Id),
    CONSTRAINT FK_Schedule_Year FOREIGN KEY (AcademicYearId) REFERENCES institutional.AcademicYear(Id),
    CONSTRAINT CK_Schedule_Day CHECK (DayOfWeek BETWEEN 1 AND 7),
    CONSTRAINT CK_Schedule_Time CHECK (EndTime > StartTime)
);
GO

CREATE INDEX IX_Schedule_Section ON academic.Schedule(SectionId, AcademicYearId);
CREATE INDEX IX_Schedule_Teacher ON academic.Schedule(TeacherAssignmentId);
CREATE INDEX IX_Schedule_Classroom ON academic.Schedule(ClassroomId, DayOfWeek, StartTime, EndTime);
GO

-- 5.18. ScheduleChangeLog
CREATE TABLE academic.ScheduleChangeLog (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    ScheduleId      INT             NOT NULL,
    ChangedById     UNIQUEIDENTIFIER NOT NULL,
    OldValues       NVARCHAR(MAX)   NULL,
    NewValues       NVARCHAR(MAX)   NULL,
    Reason          NVARCHAR(500)   NULL,
    ChangedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ScheduleLog_Schedule FOREIGN KEY (ScheduleId) REFERENCES academic.Schedule(Id),
    CONSTRAINT FK_ScheduleLog_User FOREIGN KEY (ChangedById) REFERENCES security.Users(Id)
);
GO

-- ============================================================
-- 6. TABLAS - ESQUEMA evaluation
-- ============================================================

-- 6.1. EvaluationType
CREATE TABLE evaluation.EvaluationType (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(20)     NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    Weight          DECIMAL(5,2)    NOT NULL DEFAULT 1.0,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_EvaluationType_Code UNIQUE (Code),
    CONSTRAINT CK_EvaluationType_Weight CHECK (Weight > 0)
);
GO

-- 6.2. Evaluation
CREATE TABLE evaluation.Evaluation (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    CourseId            INT             NOT NULL,
    SectionId           INT             NOT NULL,
    AcademicPeriodId    INT             NOT NULL,
    TeacherId           INT             NOT NULL,
    Title               NVARCHAR(200)   NOT NULL,
    EvaluationTypeId    INT             NOT NULL,
    MaxScore            DECIMAL(5,2)    NOT NULL DEFAULT 20,
    EvaluationDate      DATE            NOT NULL,
    IsPublished         BIT             NOT NULL DEFAULT 0,
    PublishedAt         DATETIME2       NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Evaluation_Course FOREIGN KEY (CourseId) REFERENCES academic.Course(Id),
    CONSTRAINT FK_Evaluation_Section FOREIGN KEY (SectionId) REFERENCES academic.Section(Id),
    CONSTRAINT FK_Evaluation_Period FOREIGN KEY (AcademicPeriodId) REFERENCES institutional.AcademicPeriod(Id),
    CONSTRAINT FK_Evaluation_Teacher FOREIGN KEY (TeacherId) REFERENCES academic.Teacher(Id),
    CONSTRAINT FK_Evaluation_Type FOREIGN KEY (EvaluationTypeId) REFERENCES evaluation.EvaluationType(Id),
    CONSTRAINT CK_Evaluation_MaxScore CHECK (MaxScore > 0)
);
GO

CREATE INDEX IX_Evaluation_Course ON evaluation.Evaluation(CourseId, SectionId, AcademicPeriodId);
GO

-- 6.3. StudentGrade
CREATE TABLE evaluation.StudentGrade (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    EvaluationId    INT             NOT NULL,
    StudentId       INT             NOT NULL,
    Score           DECIMAL(5,2)    NULL,
    IsPublished     BIT             NOT NULL DEFAULT 0,

    CONSTRAINT FK_StudentGrade_Evaluation FOREIGN KEY (EvaluationId) REFERENCES evaluation.Evaluation(Id),
    CONSTRAINT FK_StudentGrade_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT UQ_StudentGrade UNIQUE (EvaluationId, StudentId)
);
GO

CREATE INDEX IX_StudentGrade_Student ON evaluation.StudentGrade(StudentId);
GO

-- 6.4. BimesterAverage
CREATE TABLE evaluation.BimesterAverage (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    StudentId           INT             NOT NULL,
    CourseId            INT             NOT NULL,
    AcademicPeriodId    INT             NOT NULL,
    AverageScore        DECIMAL(5,2)    NULL,
    IsApproved          BIT             NULL,

    CONSTRAINT FK_BimesterAverage_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_BimesterAverage_Course FOREIGN KEY (CourseId) REFERENCES academic.Course(Id),
    CONSTRAINT FK_BimesterAverage_Period FOREIGN KEY (AcademicPeriodId) REFERENCES institutional.AcademicPeriod(Id),
    CONSTRAINT UQ_BimesterAverage UNIQUE (StudentId, CourseId, AcademicPeriodId)
);
GO

CREATE INDEX IX_BimesterAverage_Student ON evaluation.BimesterAverage(StudentId, AcademicPeriodId);
GO

-- 6.5. ConductScale
CREATE TABLE evaluation.ConductScale (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    EducationalLevelId  INT             NOT NULL,
    Code                VARCHAR(5)      NOT NULL,
    Name                NVARCHAR(50)    NOT NULL,
    Description         NVARCHAR(255)   NULL,
    SortOrder           INT             NOT NULL DEFAULT 0,

    CONSTRAINT FK_ConductScale_Level FOREIGN KEY (EducationalLevelId) REFERENCES academic.EducationalLevel(Id),
    CONSTRAINT UQ_ConductScale UNIQUE (EducationalLevelId, Code)
);
GO

-- 6.6. Conduct
CREATE TABLE evaluation.Conduct (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    StudentId           INT             NOT NULL,
    AcademicPeriodId    INT             NOT NULL,
    TeacherId           INT             NOT NULL,
    ConductScaleId      INT             NOT NULL,
    Description         NVARCHAR(500)   NULL,
    RecordedAt          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Conduct_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_Conduct_Period FOREIGN KEY (AcademicPeriodId) REFERENCES institutional.AcademicPeriod(Id),
    CONSTRAINT FK_Conduct_Teacher FOREIGN KEY (TeacherId) REFERENCES academic.Teacher(Id),
    CONSTRAINT FK_Conduct_Scale FOREIGN KEY (ConductScaleId) REFERENCES evaluation.ConductScale(Id)
);
GO

CREATE INDEX IX_Conduct_Student ON evaluation.Conduct(StudentId, AcademicPeriodId);
GO

-- 6.7. ObservationType
CREATE TABLE evaluation.ObservationType (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(20)     NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    IsPositive      BIT             NOT NULL DEFAULT 0,
    IsSevere        BIT             NOT NULL DEFAULT 0,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_ObservationType_Code UNIQUE (Code)
);
GO

-- 6.8. Observation
CREATE TABLE evaluation.Observation (
    Id                  INT             IDENTITY(1,1) PRIMARY KEY,
    StudentId           INT             NOT NULL,
    TeacherId           INT             NOT NULL,
    RegisteredById      UNIQUEIDENTIFIER NOT NULL,
    AcademicPeriodId    INT             NOT NULL,
    ObservationTypeId   INT             NOT NULL,
    Title               NVARCHAR(200)   NOT NULL,
    Description         NVARCHAR(MAX)   NULL,
    RecordedAt          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    IsNotified          BIT             NOT NULL DEFAULT 0,

    CONSTRAINT FK_Observation_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_Observation_Teacher FOREIGN KEY (TeacherId) REFERENCES academic.Teacher(Id),
    CONSTRAINT FK_Observation_Register FOREIGN KEY (RegisteredById) REFERENCES security.Users(Id),
    CONSTRAINT FK_Observation_Period FOREIGN KEY (AcademicPeriodId) REFERENCES institutional.AcademicPeriod(Id),
    CONSTRAINT FK_Observation_Type FOREIGN KEY (ObservationTypeId) REFERENCES evaluation.ObservationType(Id)
);
GO

CREATE INDEX IX_Observation_Student ON evaluation.Observation(StudentId, AcademicPeriodId);
GO

-- 6.9. ObservationEvidence
CREATE TABLE evaluation.ObservationEvidence (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    ObservationId   INT             NOT NULL,
    FileName        NVARCHAR(255)   NOT NULL,
    FileUrl         NVARCHAR(500)   NOT NULL,
    FileType        VARCHAR(50)     NULL,
    FileSize        BIGINT          NULL,
    UploadedAt      DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ObservationEvidence_Observation FOREIGN KEY (ObservationId) REFERENCES evaluation.Observation(Id)
);
GO

-- ============================================================
-- 7. TABLAS - ESQUEMA attendance
-- ============================================================

-- 7.1. AttendanceType
CREATE TABLE attendance.AttendanceType (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(5)      NOT NULL,
    Name            NVARCHAR(50)    NOT NULL,
    IsPresent       BIT             NOT NULL DEFAULT 0,
    IsLate          BIT             NOT NULL DEFAULT 0,
    IsAbsent        BIT             NOT NULL DEFAULT 0,
    IsJustified     BIT             NOT NULL DEFAULT 0,
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT UQ_AttendanceType_Code UNIQUE (Code)
);
GO

-- 7.2. StudentAttendance
CREATE TABLE attendance.StudentAttendance (
    Id              BIGINT          IDENTITY(1,1) PRIMARY KEY,
    StudentId       INT             NOT NULL,
    CourseId        INT             NOT NULL,
    SectionId       INT             NOT NULL,
    ScheduleId      INT             NULL,
    AttendanceDate  DATE            NOT NULL,
    AttendanceTypeId INT            NOT NULL,
    RegisteredById  UNIQUEIDENTIFIER NOT NULL,
    TimeRecorded    TIME            NOT NULL DEFAULT CAST(SYSUTCDATETIME() AS TIME),
    Observation     NVARCHAR(255)   NULL,

    CONSTRAINT FK_StudentAtt_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_StudentAtt_Course FOREIGN KEY (CourseId) REFERENCES academic.Course(Id),
    CONSTRAINT FK_StudentAtt_Section FOREIGN KEY (SectionId) REFERENCES academic.Section(Id),
    CONSTRAINT FK_StudentAtt_Schedule FOREIGN KEY (ScheduleId) REFERENCES academic.Schedule(Id),
    CONSTRAINT FK_StudentAtt_Type FOREIGN KEY (AttendanceTypeId) REFERENCES attendance.AttendanceType(Id),
    CONSTRAINT FK_StudentAtt_Register FOREIGN KEY (RegisteredById) REFERENCES security.Users(Id),
    CONSTRAINT UQ_StudentAttendance UNIQUE (StudentId, CourseId, AttendanceDate, ScheduleId)
);
GO

CREATE INDEX IX_StudentAtt_Date ON attendance.StudentAttendance(SectionId, AttendanceDate);
CREATE INDEX IX_StudentAtt_Student ON attendance.StudentAttendance(StudentId, AttendanceDate);
GO

-- 7.3. StaffAttendance
CREATE TABLE attendance.StaffAttendance (
    Id                  BIGINT          IDENTITY(1,1) PRIMARY KEY,
    PersonId            INT             NOT NULL,
    AttendanceDate      DATE            NOT NULL,
    TimeIn              TIME            NULL,
    TimeOut             TIME            NULL,
    AttendanceTypeId    INT             NOT NULL,
    IsBiometric         BIT             NOT NULL DEFAULT 0,
    BiometricDeviceId   INT             NULL,
    RegisteredById      UNIQUEIDENTIFIER NULL,
    Observation         NVARCHAR(255)   NULL,
    CreatedAt           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_StaffAtt_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT FK_StaffAtt_Type FOREIGN KEY (AttendanceTypeId) REFERENCES attendance.AttendanceType(Id),
    CONSTRAINT FK_StaffAtt_Device FOREIGN KEY (BiometricDeviceId) REFERENCES biometric.BiometricDevice(Id),
    CONSTRAINT FK_StaffAtt_Register FOREIGN KEY (RegisteredById) REFERENCES security.Users(Id),
    CONSTRAINT UQ_StaffAttendance UNIQUE (PersonId, AttendanceDate)
);
GO

CREATE INDEX IX_StaffAtt_Date ON attendance.StaffAttendance(AttendanceDate);
CREATE INDEX IX_StaffAtt_Person ON attendance.StaffAttendance(PersonId, AttendanceDate);
GO

-- 7.4. StudentAttendanceSummary
CREATE TABLE attendance.StudentAttendanceSummary (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    StudentId       INT             NOT NULL,
    AcademicPeriodId INT            NOT NULL,
    TotalDays       INT             NOT NULL DEFAULT 0,
    PresentDays     INT             NOT NULL DEFAULT 0,
    LateDays        INT             NOT NULL DEFAULT 0,
    AbsentDays      INT             NOT NULL DEFAULT 0,
    JustifiedDays   INT             NOT NULL DEFAULT 0,
    Percentage      DECIMAL(5,2)    NULL,
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_StudentAttSum_Student FOREIGN KEY (StudentId) REFERENCES academic.Student(Id),
    CONSTRAINT FK_StudentAttSum_Period FOREIGN KEY (AcademicPeriodId) REFERENCES institutional.AcademicPeriod(Id),
    CONSTRAINT UQ_StudentAttSum UNIQUE (StudentId, AcademicPeriodId)
);
GO

-- 7.5. StaffAttendanceSummary
CREATE TABLE attendance.StaffAttendanceSummary (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    PersonId        INT             NOT NULL,
    AcademicPeriodId INT            NOT NULL,
    TotalDays       INT             NOT NULL DEFAULT 0,
    PresentDays     INT             NOT NULL DEFAULT 0,
    LateDays        INT             NOT NULL DEFAULT 0,
    AbsentDays      INT             NOT NULL DEFAULT 0,
    JustifiedDays   INT             NOT NULL DEFAULT 0,
    Percentage      DECIMAL(5,2)    NULL,
    UpdatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_StaffAttSum_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT FK_StaffAttSum_Period FOREIGN KEY (AcademicPeriodId) REFERENCES institutional.AcademicPeriod(Id),
    CONSTRAINT UQ_StaffAttSum UNIQUE (PersonId, AcademicPeriodId)
);
GO

-- ============================================================
-- 8. TABLAS - ESQUEMA communication
-- ============================================================

-- 8.1. Communication
CREATE TABLE communication.Communication (
    Id                      INT             IDENTITY(1,1) PRIMARY KEY,
    Title                   NVARCHAR(200)   NOT NULL,
    Content                 NVARCHAR(MAX)   NOT NULL,
    PublishedById           UNIQUEIDENTIFIER NOT NULL,
    PublishedAt             DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    ExpiresAt               DATETIME2       NULL,
    IsActive                BIT             NOT NULL DEFAULT 1,
    RequiresConfirmation    BIT             NOT NULL DEFAULT 0,
    IsUrgent                BIT             NOT NULL DEFAULT 0,
    CreatedAt               DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Communication_Publisher FOREIGN KEY (PublishedById) REFERENCES security.Users(Id)
);
GO

CREATE INDEX IX_Communication_Active ON communication.Communication(IsActive, PublishedAt);
GO

-- 8.2. CommunicationAttachment
CREATE TABLE communication.CommunicationAttachment (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    CommunicationId INT             NOT NULL,
    FileName        NVARCHAR(255)   NOT NULL,
    FileUrl         NVARCHAR(500)   NOT NULL,
    FileSize        BIGINT          NULL,
    ContentType     VARCHAR(100)    NULL,

    CONSTRAINT FK_CommAttachment_Comm FOREIGN KEY (CommunicationId) REFERENCES communication.Communication(Id)
);
GO

-- 8.3. CommunicationTarget
CREATE TABLE communication.CommunicationTarget (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    CommunicationId INT             NOT NULL,
    TargetType      VARCHAR(30)     NOT NULL,
    TargetId        VARCHAR(50)     NULL,

    CONSTRAINT FK_CommTarget_Comm FOREIGN KEY (CommunicationId) REFERENCES communication.Communication(Id),
    CONSTRAINT CK_CommTarget_Type CHECK (TargetType IN ('Role', 'Section', 'All', 'Individual', 'Grade', 'Level'))
);
GO

CREATE INDEX IX_CommTarget_Comm ON communication.CommunicationTarget(CommunicationId);
GO

-- 8.4. CommunicationReadConfirmation
CREATE TABLE communication.CommunicationReadConfirmation (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    CommunicationId INT             NOT NULL,
    UserId          UNIQUEIDENTIFIER NOT NULL,
    ReadAt          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_CommRead_Comm FOREIGN KEY (CommunicationId) REFERENCES communication.Communication(Id),
    CONSTRAINT FK_CommRead_User FOREIGN KEY (UserId) REFERENCES security.Users(Id),
    CONSTRAINT UQ_CommRead UNIQUE (CommunicationId, UserId)
);
GO

-- ============================================================
-- 9. TABLAS - ESQUEMA biometric
-- ============================================================

-- 9.1. BiometricDevice
CREATE TABLE biometric.BiometricDevice (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(50)     NOT NULL,
    Name            NVARCHAR(100)   NOT NULL,
    Model           VARCHAR(100)    NULL,
    SerialNumber    VARCHAR(100)    NULL,
    Location        NVARCHAR(100)   NULL,
    IpAddress       VARCHAR(45)     NULL,
    Port            INT             NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    LastConnection  DATETIME2       NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT UQ_BiometricDevice_Code UNIQUE (Code)
);
GO

-- 9.2. FingerprintTemplate
CREATE TABLE biometric.FingerprintTemplate (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    PersonId        INT             NOT NULL,
    TemplateData    VARBINARY(MAX)  NOT NULL,
    TemplateFormat  VARCHAR(50)     NOT NULL DEFAULT 'ISOTemplate',
    FingerIndex     INT             NOT NULL,
    DeviceId        INT             NOT NULL,
    RegisteredAt    DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    IsActive        BIT             NOT NULL DEFAULT 1,

    CONSTRAINT FK_Fingerprint_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT FK_Fingerprint_Device FOREIGN KEY (DeviceId) REFERENCES biometric.BiometricDevice(Id),
    CONSTRAINT CK_Fingerprint_Index CHECK (FingerIndex BETWEEN 1 AND 10),
    CONSTRAINT UQ_Fingerprint UNIQUE (PersonId, FingerIndex)
);
GO

CREATE INDEX IX_Fingerprint_Person ON biometric.FingerprintTemplate(PersonId) WHERE IsActive = 1;
GO

-- 9.3. BiometricLog
CREATE TABLE biometric.BiometricLog (
    Id              BIGINT          IDENTITY(1,1) PRIMARY KEY,
    DeviceId        INT             NOT NULL,
    PersonId        INT             NULL,
    Timestamp       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    EventType       VARCHAR(10)     NOT NULL,
    MatchStatus     VARCHAR(10)     NOT NULL,
    TemplateVersion INT             NULL,
    RawData         VARCHAR(MAX)    NULL,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_BioLog_Device FOREIGN KEY (DeviceId) REFERENCES biometric.BiometricDevice(Id),
    CONSTRAINT FK_BioLog_Person FOREIGN KEY (PersonId) REFERENCES academic.Person(Id),
    CONSTRAINT CK_BioLog_Event CHECK (EventType IN ('In', 'Out', 'Unknown')),
    CONSTRAINT CK_BioLog_Match CHECK (MatchStatus IN ('Success', 'Fail', 'Timeout'))
);
GO

CREATE INDEX IX_BioLog_Device ON biometric.BiometricLog(DeviceId, Timestamp);
CREATE INDEX IX_BioLog_Person ON biometric.BiometricLog(PersonId, Timestamp);
GO

-- 9.4. BiometricSyncLog
CREATE TABLE biometric.BiometricSyncLog (
    Id              INT             IDENTITY(1,1) PRIMARY KEY,
    DeviceId        INT             NOT NULL,
    LastSyncAt      DATETIME2       NOT NULL,
    RecordsProcessed INT            NOT NULL DEFAULT 0,
    Status          VARCHAR(20)     NOT NULL,
    ErrorMessage    NVARCHAR(MAX)   NULL,

    CONSTRAINT FK_BioSync_Device FOREIGN KEY (DeviceId) REFERENCES biometric.BiometricDevice(Id),
    CONSTRAINT CK_BioSync_Status CHECK (Status IN ('Success', 'Partial', 'Failed'))
);
GO

-- ============================================================
-- 10. TABLAS - ESQUEMA audit
-- ============================================================

-- 10.1. AuditLog
CREATE TABLE audit.AuditLog (
    Id              BIGINT          IDENTITY(1,1) PRIMARY KEY,
    UserId          UNIQUEIDENTIFIER NULL,
    UserName        VARCHAR(100)    NULL,
    Action          VARCHAR(50)     NOT NULL,
    Entity          VARCHAR(100)    NOT NULL,
    EntityId        VARCHAR(50)     NULL,
    OldValues       NVARCHAR(MAX)   NULL,
    NewValues       NVARCHAR(MAX)   NULL,
    IpAddress       VARCHAR(45)     NOT NULL,
    UserAgent       NVARCHAR(500)   NULL,
    Endpoint        VARCHAR(200)    NULL,
    DurationMs      INT             NULL,
    Timestamp       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX IX_AuditLog_Timestamp ON audit.AuditLog(Timestamp DESC);
CREATE INDEX IX_AuditLog_User ON audit.AuditLog(UserId, Timestamp);
CREATE INDEX IX_AuditLog_Entity ON audit.AuditLog(Entity, EntityId);
CREATE INDEX IX_AuditLog_Action ON audit.AuditLog(Action, Timestamp);
GO

-- 10.2. AuditLog_Archive (para particionamiento histórico)
CREATE TABLE audit.AuditLog_Archive (
    Id              BIGINT          NOT NULL,
    UserId          UNIQUEIDENTIFIER NULL,
    UserName        VARCHAR(100)    NULL,
    Action          VARCHAR(50)     NOT NULL,
    Entity          VARCHAR(100)    NOT NULL,
    EntityId        VARCHAR(50)     NULL,
    OldValues       NVARCHAR(MAX)   NULL,
    NewValues       NVARCHAR(MAX)   NULL,
    IpAddress       VARCHAR(45)     NOT NULL,
    UserAgent       NVARCHAR(500)   NULL,
    Endpoint        VARCHAR(200)    NULL,
    DurationMs      INT             NULL,
    Timestamp       DATETIME2       NOT NULL,

    CONSTRAINT PK_AuditLog_Archive PRIMARY KEY (Id, Timestamp)
);
GO

-- 10.3. ErrorLog
CREATE TABLE audit.ErrorLog (
    Id              BIGINT          IDENTITY(1,1) PRIMARY KEY,
    UserId          UNIQUEIDENTIFIER NULL,
    ExceptionType   VARCHAR(255)    NOT NULL,
    Message         NVARCHAR(MAX)   NOT NULL,
    StackTrace      NVARCHAR(MAX)   NULL,
    Source          VARCHAR(255)    NULL,
    Endpoint        VARCHAR(200)    NULL,
    IpAddress       VARCHAR(45)     NULL,
    Severity        VARCHAR(20)     NOT NULL DEFAULT 'Error',
    Timestamp       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT CK_ErrorLog_Severity CHECK (Severity IN ('Info', 'Warning', 'Error', 'Critical'))
);
GO

CREATE INDEX IX_ErrorLog_Severity ON audit.ErrorLog(Severity, Timestamp);
CREATE INDEX IX_ErrorLog_Timestamp ON audit.ErrorLog(Timestamp DESC);
GO

-- ============================================================
-- 11. DATOS INICIALES (Seed Data)
-- ============================================================

-- 11.1. Educational Levels
INSERT INTO academic.EducationalLevel (Code, Name, SortOrder) VALUES
('INI', N'Inicial', 1),
('PRI', N'Primaria', 2),
('SEC', N'Secundaria', 3);
GO

-- 11.2. Shifts
INSERT INTO academic.Shift (Code, Name) VALUES
('MAN', N'Mañana'),
('TAR', N'Tarde');
GO

-- 11.3. Attendance Types
INSERT INTO attendance.AttendanceType (Code, Name, IsPresent, IsLate, IsAbsent, IsJustified) VALUES
('P', N'Presente', 1, 0, 0, 0),
('T', N'Tardanza', 0, 1, 0, 0),
('F', N'Falta', 0, 0, 1, 0),
('J', N'Justificado', 0, 0, 1, 1);
GO

-- 11.4. Evaluation Types
INSERT INTO evaluation.EvaluationType (Code, Name, Weight) VALUES
('PRACTICA', N'Práctica', 0.20),
('EXAMEN', N'Examen', 0.30),
('TRABAJO', N'Trabajo', 0.25),
('PROYECTO', N'Proyecto', 0.15),
('PARTICIPACION', N'Participación', 0.10);
GO

-- 11.5. Conduct Scales
INSERT INTO evaluation.ConductScale (EducationalLevelId, Code, Name, Description, SortOrder)
SELECT Id, 'AD', N'Logro destacado', N'Demuestra comportamiento ejemplar constantemente.', 1
FROM academic.EducationalLevel
UNION ALL
SELECT Id, 'A', N'Logro esperado', N'Cumple con las normas de convivencia.', 2
FROM academic.EducationalLevel
UNION ALL
SELECT Id, 'B', N'En proceso', N'Requiere mejorar su comportamiento.', 3
FROM academic.EducationalLevel
UNION ALL
SELECT Id, 'C', N'En inicio', N'Presenta dificultades para cumplir normas.', 4
FROM academic.EducationalLevel;
GO

-- 11.6. Observation Types
INSERT INTO evaluation.ObservationType (Code, Name, IsPositive, IsSevere) VALUES
('FELICITACION', N'Felicitación', 1, 0),
('ESFUERZO', N'Reconocimiento al esfuerzo', 1, 0),
('LLAMADO_ATENCION', N'Llamado de atención', 0, 0),
('INCUMPLIMIENTO', N'Incumplimiento de normas', 0, 0),
('FALTA_GRAVE', N'Falta grave', 0, 1),
('FALTA_MUY_GRAVE', N'Falta muy grave', 0, 1);
GO

-- 11.7. Roles del Sistema
INSERT INTO security.Roles (Name, NormalizedName, Description, IsSystem) VALUES
('SuperAdmin', 'SUPERADMIN', N'Control total del sistema', 1),
('Director', 'DIRECTOR', N'Máxima autoridad institucional', 1),
('Subdirector', 'SUBDIRECTOR', N'Supervisión académica y administrativa', 1),
('Docente', 'DOCENTE', N'Registro académico y de asistencia', 1),
('Auxiliar', 'AUXILIAR', N'Apoyo en aula y asistencia', 1),
('Administrativo', 'ADMINISTRATIVO', N'Gestión administrativa y matrículas', 1),
('Padre', 'PADRE', N'Consulta de información de sus hijos', 1);
GO

-- 11.8. Permisos base del sistema
INSERT INTO security.Permissions (Code, Name, Description, Module) VALUES
('USERS_VIEW', N'Ver usuarios', N'Visualizar listado de usuarios', 'Seguridad'),
('USERS_CREATE', N'Crear usuarios', N'Crear nuevos usuarios', 'Seguridad'),
('USERS_EDIT', N'Editar usuarios', N'Modificar datos de usuarios', 'Seguridad'),
('USERS_DELETE', N'Eliminar usuarios', N'Desactivar/eliminar usuarios', 'Seguridad'),
('ROLES_MANAGE', N'Gestionar roles', N'Administrar roles y permisos', 'Seguridad'),
('STUDENTS_VIEW', N'Ver estudiantes', N'Visualizar estudiantes', 'Académico'),
('STUDENTS_CREATE', N'Crear estudiantes', N'Registrar nuevos estudiantes', 'Académico'),
('STUDENTS_EDIT', N'Editar estudiantes', N'Modificar datos de estudiantes', 'Académico'),
('STUDENTS_DELETE', N'Eliminar estudiantes', N'Archivar estudiantes', 'Académico'),
('TEACHERS_VIEW', N'Ver docentes', N'Visualizar docentes', 'Académico'),
('TEACHERS_CREATE', N'Crear docentes', N'Registrar docentes', 'Académico'),
('TEACHERS_EDIT', N'Editar docentes', N'Modificar docentes', 'Académico'),
('ENROLLMENT_CREATE', N'Realizar matrícula', N'Registrar matrículas', 'Académico'),
('ENROLLMENT_VIEW', N'Ver matrículas', N'Visualizar matrículas', 'Académico'),
('COURSES_MANAGE', N'Gestionar cursos', N'Administrar cursos y áreas', 'Académico'),
('SCHEDULES_MANAGE', N'Gestionar horarios', N'Administrar horarios', 'Académico'),
('GRADES_MANAGE', N'Gestionar grados', N'Administrar grados y secciones', 'Académico'),
('NOTES_REGISTER', N'Registrar notas', N'Registrar calificaciones', 'Evaluación'),
('NOTES_VIEW', N'Ver notas', N'Visualizar calificaciones', 'Evaluación'),
('NOTES_PUBLISH', N'Publicar notas', N'Publicar notas para padres', 'Evaluación'),
('ATTENDANCE_REGISTER', N'Registrar asistencia', N'Registrar asistencia de estudiantes', 'Asistencia'),
('ATTENDANCE_VIEW', N'Ver asistencia', N'Visualizar reportes de asistencia', 'Asistencia'),
('BIOMETRIC_MANAGE', N'Gestionar biometría', N'Administrar dispositivos y huellas', 'Biométrico'),
('CONDUCT_REGISTER', N'Registrar conducta', N'Registrar conducta y observaciones', 'Evaluación'),
('COMMUNICATIONS_CREATE', N'Crear comunicados', N'Publicar comunicados', 'Comunicación'),
('COMMUNICATIONS_VIEW', N'Ver comunicados', N'Visualizar comunicados', 'Comunicación'),
('REPORTS_VIEW', N'Ver reportes', N'Acceder a reportes y dashboards', 'Reportes'),
('REPORTS_EXPORT', N'Exportar reportes', N'Exportar reportes a PDF/Excel', 'Reportes'),
('CONFIG_MANAGE', N'Configurar sistema', N'Administrar configuración global', 'Sistema'),
('AUDIT_VIEW', N'Ver auditoría', N'Consultar logs de auditoría', 'Sistema'),
('PORTAL_MANAGE', N'Gestionar portal', N'Administrar contenido del portal', 'Portal'),
('PARENT_CONSULT', N'Consulta de padres', N'Acceder a consultas de padre de familia', 'Portal');
GO

-- 11.9. Asignar permisos a SuperAdmin (todos los permisos)
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'SuperAdmin'), Id
FROM security.Permissions;
GO

-- 11.10. Asignar permisos a Director
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'Director'), Id
FROM security.Permissions
WHERE Code IN (
    'STUDENTS_VIEW', 'TEACHERS_VIEW', 'ENROLLMENT_VIEW',
    'COURSES_MANAGE', 'SCHEDULES_MANAGE', 'GRADES_MANAGE',
    'NOTES_VIEW', 'NOTES_PUBLISH', 'ATTENDANCE_VIEW',
    'CONDUCT_REGISTER', 'COMMUNICATIONS_CREATE', 'COMMUNICATIONS_VIEW',
    'REPORTS_VIEW', 'REPORTS_EXPORT', 'BIOMETRIC_MANAGE',
    'PORTAL_MANAGE', 'CONFIG_MANAGE', 'AUDIT_VIEW'
);
GO

-- 11.11. Asignar permisos a Subdirector
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'Subdirector'), Id
FROM security.Permissions
WHERE Code IN (
    'STUDENTS_VIEW', 'STUDENTS_CREATE', 'STUDENTS_EDIT',
    'TEACHERS_VIEW', 'ENROLLMENT_VIEW',
    'COURSES_MANAGE', 'SCHEDULES_MANAGE', 'GRADES_MANAGE',
    'NOTES_VIEW', 'ATTENDANCE_VIEW',
    'CONDUCT_REGISTER', 'COMMUNICATIONS_CREATE', 'COMMUNICATIONS_VIEW',
    'REPORTS_VIEW', 'REPORTS_EXPORT'
);
GO

-- 11.12. Asignar permisos a Docente
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'Docente'), Id
FROM security.Permissions
WHERE Code IN (
    'STUDENTS_VIEW', 'NOTES_REGISTER', 'NOTES_VIEW',
    'ATTENDANCE_REGISTER', 'ATTENDANCE_VIEW',
    'CONDUCT_REGISTER', 'COMMUNICATIONS_VIEW'
);
GO

-- 11.13. Asignar permisos a Auxiliar
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'Auxiliar'), Id
FROM security.Permissions
WHERE Code IN (
    'STUDENTS_VIEW', 'ATTENDANCE_REGISTER', 'ATTENDANCE_VIEW',
    'COMMUNICATIONS_VIEW'
);
GO

-- 11.14. Asignar permisos a Administrativo
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'Administrativo'), Id
FROM security.Permissions
WHERE Code IN (
    'STUDENTS_VIEW', 'STUDENTS_CREATE', 'STUDENTS_EDIT',
    'ENROLLMENT_CREATE', 'ENROLLMENT_VIEW',
    'NOTES_VIEW', 'ATTENDANCE_VIEW',
    'COMMUNICATIONS_CREATE', 'COMMUNICATIONS_VIEW',
    'REPORTS_VIEW', 'REPORTS_EXPORT'
);
GO

-- 11.15. Asignar permisos a Padre
INSERT INTO security.RolePermissions (RoleId, PermissionId)
SELECT (SELECT Id FROM security.Roles WHERE Name = 'Padre'), Id
FROM security.Permissions
WHERE Code IN (
    'NOTES_VIEW', 'ATTENDANCE_VIEW', 'COMMUNICATIONS_VIEW',
    'PARENT_CONSULT'
);
GO

-- 11.16. Configuración inicial del sitio
INSERT INTO institutional.SiteSetting ([Key], Value, Description) VALUES
('SiteName', N'IE Abraham Valdelomar N.° 116', N'Nombre del sitio'),
('SiteDescription', N'Sistema Inteligente de Gestión Académica y Control Biométrico', N'Descripción del sitio'),
('MaintenanceMode', 'false', N'Modo mantenimiento'),
('MaxLoginAttempts', '5', N'Intentos máximos de login'),
('LockoutMinutes', '15', N'Minutos de bloqueo por intentos fallidos'),
('PasswordExpirationDays', '90', N'Días de expiración de contraseña'),
('SessionTimeoutMinutes', '30', N'Tiempo de inactividad para cierre automático'),
('MinGradeApproval', '11', N'Nota mínima aprobatoria'),
('DefaultPageSize', '25', N'Registros por página por defecto');
GO

-- ============================================================
-- 12. ÍNDICES ADICIONALES PARA RENDIMIENTO
-- ============================================================

-- Índice compuesto para búsqueda de estudiantes
CREATE NONCLUSTERED INDEX IX_Student_Search
ON academic.Student(StudentCode)
INCLUDE (PersonId, IsActive);
GO

-- Índice para reportes de asistencia por periodo
CREATE NONCLUSTERED INDEX IX_StudentAttendance_Report
ON attendance.StudentAttendance(AttendanceDate, SectionId, CourseId)
INCLUDE (StudentId, AttendanceTypeId);
GO

-- Índice para evaluaciones por periodo
CREATE NONCLUSTERED INDEX IX_Evaluation_Period
ON evaluation.Evaluation(AcademicPeriodId, CourseId, SectionId)
INCLUDE (TeacherId, IsPublished);
GO

-- Índice para promedios bimestrales
CREATE NONCLUSTERED INDEX IX_BimesterAverage_Report
ON evaluation.BimesterAverage(AcademicPeriodId, StudentId)
INCLUDE (CourseId, AverageScore, IsApproved);
GO

-- Índice para horarios sin conflictos
CREATE UNIQUE NONCLUSTERED INDEX IX_Schedule_NoConflict
ON academic.Schedule(DayOfWeek, StartTime, EndTime, ClassroomId, ShiftId)
WHERE IsActive = 1;
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Schedule_TeacherNoConflict
ON academic.Schedule(DayOfWeek, StartTime, EndTime, TeacherAssignmentId, ShiftId)
WHERE IsActive = 1;
GO

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
PRINT 'Base de datos SIGA-116 creada exitosamente.';
GO
