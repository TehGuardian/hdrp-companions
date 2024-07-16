CREATE TABLE IF NOT EXISTS `tbrp_companions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `stablepet` varchar(50) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `dogid` varchar(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `dog` varchar(50) DEFAULT NULL,
  `dirt` INT(11) NULL DEFAULT '0',
  `skin` INT(11) NULL DEFAULT '0',
  `dogxp` int(11) DEFAULT 0,
  `gender` varchar(11) NOT NULL,
  `active` tinyint(4) DEFAULT 0,
  `born` int(11) NOT NULL DEFAULT 0,
  `wild` varchar(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;