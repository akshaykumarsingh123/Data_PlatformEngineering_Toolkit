-- Disable all table constraints
ALTER TABLE YourTableName NOCHECK CONSTRAINT ALL
-- Enable all table constraints
ALTER TABLE YourTableName CHECK CONSTRAINT ALL

-- ----------

-- Disable single constraint
ALTER TABLE YourTableName NOCHECK CONSTRAINT YourConstraint
-- Enable single constraint
ALTER TABLE YourTableName CHECK CONSTRAINT YourConstraint

-- ----------

-- Disable all constraints for database
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
-- Enable all constraints for database
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"