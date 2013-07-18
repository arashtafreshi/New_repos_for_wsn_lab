-- phpMyAdmin SQL Dump
-- version 4.0.4
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Jul 18, 2013 at 10:13 AM
-- Server version: 5.5.32
-- PHP Version: 5.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `wsn_lab`
--
CREATE DATABASE IF NOT EXISTS `wsn_lab` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `wsn_lab`;

-- --------------------------------------------------------

--
-- Table structure for table `activity`
--

CREATE TABLE IF NOT EXISTS `activity` (
  `ActivityID` int(11) NOT NULL,
  `ActivityName` varchar(40) NOT NULL,
  PRIMARY KEY (`ActivityID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `file`
--

CREATE TABLE IF NOT EXISTS `file` (
  `ActivityID` int(11) NOT NULL,
  `ExeFile` longblob NOT NULL,
  PRIMARY KEY (`ActivityID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `group`
--

CREATE TABLE IF NOT EXISTS `group` (
  `GroupID` int(11) NOT NULL,
  `GroupName` varchar(40) NOT NULL,
  `GroupPlace` varchar(40) NOT NULL,
  PRIMARY KEY (`GroupID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `job`
--

CREATE TABLE IF NOT EXISTS `job` (
  `JobID` int(11) NOT NULL AUTO_INCREMENT,
  `MoteID` int(11) NOT NULL,
  `GroupID` int(11) NOT NULL,
  `ActivityID` int(11) NOT NULL,
  `JobDate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UserID` int(11) NOT NULL,
  PRIMARY KEY (`JobID`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `job`
--

INSERT INTO `job` (`JobID`, `MoteID`, `GroupID`, `ActivityID`, `JobDate`, `UserID`) VALUES
(1, 2, 2, 1, '2013-07-18 08:12:09', 2);

-- --------------------------------------------------------

--
-- Table structure for table `mote`
--

CREATE TABLE IF NOT EXISTS `mote` (
  `MoteID` int(11) NOT NULL,
  `MoteName` varchar(40) NOT NULL,
  `GroupID` int(11) NOT NULL,
  PRIMARY KEY (`MoteID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `mote`
--

INSERT INTO `mote` (`MoteID`, `MoteName`, `GroupID`) VALUES
(0, 'Amy', 0),
(1, 'Stuart', 0),
(2, 'Barry', 0);

-- --------------------------------------------------------

--
-- Table structure for table `neighbor`
--

CREATE TABLE IF NOT EXISTS `neighbor` (
  `GroupID` int(11) NOT NULL,
  `SourceID` int(11) NOT NULL,
  `DestID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE IF NOT EXISTS `user` (
  `UserID` int(11) NOT NULL,
  `UserName` varchar(40) NOT NULL,
  `UserPass` varchar(40) NOT NULL,
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
