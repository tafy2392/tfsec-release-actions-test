resource "aws_db_parameter_group" "rds_postgres_parameter_group" {
  name        = "db-parameter-group"
  family      = "postgres11"
}
