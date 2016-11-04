-- phpMyAdmin SQL Dump
-- version 4.2.10
-- http://www.phpmyadmin.net
--
-- Servidor: localhost:8889
-- Tiempo de generación: 04-11-2016 a las 22:36:18
-- Versión del servidor: 5.5.38
-- Versión de PHP: 5.6.2

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Base de datos: `lowres`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Comments`
--

CREATE TABLE `Comments` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post` varchar(10) NOT NULL,
  `user` varchar(10) DEFAULT NULL,
  `text` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Follows`
--

CREATE TABLE `Follows` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `user` varchar(10) NOT NULL,
  `followsUser` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Likes`
--

CREATE TABLE `Likes` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post` varchar(10) NOT NULL,
  `user` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Notifications`
--

CREATE TABLE `Notifications` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `sender` varchar(10) NOT NULL,
  `recipient` varchar(10) NOT NULL,
  `post` varchar(10) DEFAULT NULL,
  `type` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Posts`
--

CREATE TABLE `Posts` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `type` int(11) NOT NULL,
  `category` int(11) NOT NULL,
  `user` varchar(10) NOT NULL,
  `title` text NOT NULL,
  `detail` text,
  `image` text,
  `program` text,
  `sharedPost` varchar(10) DEFAULT NULL,
  `stats` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `PostStats`
--

CREATE TABLE `PostStats` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post` varchar(10) NOT NULL,
  `numDownloads` int(11) NOT NULL,
  `numComments` int(11) NOT NULL,
  `numLikes` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Users`
--

CREATE TABLE `Users` (
  `objectId` varchar(10) NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `username` varchar(60) NOT NULL,
  `bcryptPassword` varchar(60) NOT NULL,
  `sessionToken` varchar(25) DEFAULT NULL,
  `lastPostDate` timestamp NULL DEFAULT NULL,
  `notificationsOpenedDate` timestamp NULL DEFAULT NULL,
  `about` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `Comments`
--
ALTER TABLE `Comments`
 ADD PRIMARY KEY (`objectId`);

--
-- Indices de la tabla `Follows`
--
ALTER TABLE `Follows`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `userPair` (`user`,`followsUser`);

--
-- Indices de la tabla `Likes`
--
ALTER TABLE `Likes`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `userPostPair` (`user`,`post`);

--
-- Indices de la tabla `Notifications`
--
ALTER TABLE `Notifications`
 ADD PRIMARY KEY (`objectId`);

--
-- Indices de la tabla `Posts`
--
ALTER TABLE `Posts`
 ADD PRIMARY KEY (`objectId`);

--
-- Indices de la tabla `PostStats`
--
ALTER TABLE `PostStats`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `post` (`post`);

--
-- Indices de la tabla `Users`
--
ALTER TABLE `Users`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `username` (`username`), ADD UNIQUE KEY `sessionToken` (`sessionToken`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
