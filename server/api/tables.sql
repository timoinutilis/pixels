-- phpMyAdmin SQL Dump
-- version 4.2.10
-- http://www.phpmyadmin.net
--
-- Servidor: localhost:8889
-- Tiempo de generación: 04-01-2017 a las 23:12:57
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
-- Estructura de tabla para la tabla `comments`
--

CREATE TABLE `comments` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `user` varchar(10) COLLATE utf8mb4_bin DEFAULT NULL,
  `text` text COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `follows`
--

CREATE TABLE `follows` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `user` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `followsUser` varchar(10) COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `likes`
--

CREATE TABLE `likes` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `user` varchar(10) COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notifications`
--

CREATE TABLE `notifications` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `sender` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `recipient` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `post` varchar(10) COLLATE utf8mb4_bin DEFAULT NULL,
  `type` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `posts`
--

CREATE TABLE `posts` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `type` int(11) NOT NULL,
  `category` int(11) NOT NULL,
  `user` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `title` text COLLATE utf8mb4_bin NOT NULL,
  `detail` text COLLATE utf8mb4_bin,
  `image` text COLLATE utf8mb4_bin,
  `program` text COLLATE utf8mb4_bin,
  `sharedPost` varchar(10) COLLATE utf8mb4_bin DEFAULT NULL,
  `stats` varchar(10) COLLATE utf8mb4_bin DEFAULT NULL,
  `featured` tinyint(1) NOT NULL DEFAULT '0',
  `highlighted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `postStats`
--

CREATE TABLE `postStats` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `post` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `numDownloads` int(11) NOT NULL,
  `numComments` int(11) NOT NULL,
  `numLikes` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `objectId` varchar(10) COLLATE utf8mb4_bin NOT NULL,
  `updatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `createdAt` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `username` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `bcryptPassword` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `sessionToken` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `lastPostDate` timestamp NULL DEFAULT NULL,
  `notificationsOpenedDate` timestamp NULL DEFAULT NULL,
  `about` text COLLATE utf8mb4_bin
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `comments`
--
ALTER TABLE `comments`
 ADD PRIMARY KEY (`objectId`);

--
-- Indices de la tabla `follows`
--
ALTER TABLE `follows`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `userPair` (`user`,`followsUser`);

--
-- Indices de la tabla `likes`
--
ALTER TABLE `likes`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `userPostPair` (`user`,`post`);

--
-- Indices de la tabla `notifications`
--
ALTER TABLE `notifications`
 ADD PRIMARY KEY (`objectId`);

--
-- Indices de la tabla `posts`
--
ALTER TABLE `posts`
 ADD PRIMARY KEY (`objectId`);

--
-- Indices de la tabla `postStats`
--
ALTER TABLE `postStats`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `post` (`post`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
 ADD PRIMARY KEY (`objectId`), ADD UNIQUE KEY `username` (`username`), ADD UNIQUE KEY `sessionToken` (`sessionToken`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
