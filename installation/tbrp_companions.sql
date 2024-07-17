CREATE TABLE `tbrp_companions` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`stablepet` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`citizenid` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`dogid` VARCHAR(11) NOT NULL COLLATE 'utf8mb4_general_ci',
	`name` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	`dog` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`dirt` INT(11) NULL DEFAULT '0',
	`skin` INT(11) NULL DEFAULT '0',
	`dogxp` INT(11) NULL DEFAULT '0',
	`gender` VARCHAR(11) NOT NULL COLLATE 'utf8mb4_general_ci',
	`active` TINYINT(4) NULL DEFAULT '0',
	`born` INT(11) NOT NULL DEFAULT '0',
	`wild` VARCHAR(11) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
;
