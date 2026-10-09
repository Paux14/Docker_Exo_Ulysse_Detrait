-- Initialisation de la base kennelDB (exécutée au premier démarrage du conteneur)
-- Force l'UTF-8 pour la lecture de ce script (sinon les accents sont double-encodés)
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS kennelDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE kennelDB;

CREATE TABLE clients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50) NOT NULL,
  date_naissance DATE NOT NULL,
  pseudonyme VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE adresses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  numero VARCHAR(10) NOT NULL,
  rue VARCHAR(100) NOT NULL,
  code_postal VARCHAR(10) NOT NULL,
  commune VARCHAR(80) NOT NULL
);

-- Association N-N : un client peut avoir plusieurs adresses, une adresse peut être partagée
CREATE TABLE clients_adresses (
  client_id INT NOT NULL,
  adresse_id INT NOT NULL,
  PRIMARY KEY (client_id, adresse_id),
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
  FOREIGN KEY (adresse_id) REFERENCES adresses(id) ON DELETE CASCADE
);

CREATE TABLE chiens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  date_naissance DATE NOT NULL,
  race VARCHAR(60) NOT NULL,
  sterilise BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE chats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  date_naissance DATE NOT NULL,
  race VARCHAR(60) NOT NULL,
  sterilise BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO clients (nom, prenom, date_naissance, pseudonyme) VALUES
  ('Martin',  'Alice',  '1990-04-12', 'alice_m'),
  ('Dupont',  'Bruno',  '1985-11-03', 'bruno85'),
  ('Lefebvre','Chloé',  '1998-07-21', 'chloe_l'),
  ('Moreau',  'David',  '1979-02-09', 'dmoreau');

INSERT INTO adresses (numero, rue, code_postal, commune) VALUES
  ('12',  'rue des Lilas',        '75011', 'Paris'),
  ('5',   'avenue Victor Hugo',   '69003', 'Lyon'),
  ('48',  'boulevard Gambetta',   '33000', 'Bordeaux'),
  ('3 bis','impasse du Moulin',   '31000', 'Toulouse');

INSERT INTO clients_adresses (client_id, adresse_id) VALUES
  (1, 1),
  (1, 2),
  (2, 2),
  (3, 3),
  (4, 4);

INSERT INTO chiens (nom, date_naissance, race, sterilise) VALUES
  ('Rex',   '2019-05-14', 'Berger allemand', TRUE),
  ('Luna',  '2021-09-02', 'Labrador',        FALSE),
  ('Milo',  '2018-01-30', 'Beagle',          TRUE);

INSERT INTO chats (nom, date_naissance, race, sterilise) VALUES
  ('Félix', '2020-03-18', 'Européen',   TRUE),
  ('Nala',  '2022-06-25', 'Maine Coon', FALSE),
  ('Tigrou','2017-12-08', 'Siamois',    TRUE);
