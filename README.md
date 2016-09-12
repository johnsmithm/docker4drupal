This is a docker instalation for drupal 7

In order to connect to an external database Set the enviroment variable from drupal-web image.
In order to connect to a local database one needs to set up the credentials for github account. Also one need to have set the name of the file that will be unzgip and upload to mysql server.
Set also the mount folder for site directory and for mysql files.

always change *** from docker-compose to something else like 0, or your github credentials.
