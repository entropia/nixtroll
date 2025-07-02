CREATE TABLE users_export (id int(10) unsigned, name varchar(64), email varchar(254), force_active boolean, hours float);

INSERT INTO users_export
  SELECT
    users.id id,
    IF(users_settings.email_goodie, users.name, SHA2(LOWER(users.name), 256)) name,
    IF(users_settings.email_goodie, users.email, "") email,
    users_state.force_active force_active,
    0.0 hours
  FROM users
  JOIN users_settings ON users_settings.user_id = users.id
  JOIN users_state ON users_state.user_id = users.id
;

UPDATE
  users_export,
  (
    SELECT
      shift_entries.user_id user_id,
      COALESCE(SUM(
          TIMESTAMPDIFF(MINUTE, shifts.start, shifts.end) / 60
          * (
              CASE WHEN
                  HOUR(shifts.start) >= 2 AND HOUR(shifts.start) < 8
                  OR (
                      HOUR(shifts.end) > 2
                      || HOUR(shifts.end) = 2 AND MINUTE(shifts.end) > 0
                  ) AND HOUR(shifts.end) <= 8
                  OR HOUR(shifts.start) <= 2 AND HOUR(shifts.end) >= 8
              THEN
                  CASE WHEN `shift_entries`.`freeloaded_by` IS NULL
                  THEN 2
                  ELSE -4
                  END
              ELSE
                  CASE WHEN `shift_entries`.`freeloaded_by` IS NULL
                  THEN 1
                  ELSE -2
                  END
              END
          )
      ), 0) shift_duration
    FROM shift_entries
    JOIN shifts ON shift_entries.shift_id = shifts.id
    GROUP BY shift_entries.user_id
  ) AS shift_hours
SET
  users_export.hours = shift_hours.shift_duration
WHERE
  users_export.id = shift_hours.user_id
;

DELETE FROM users_export WHERE hours = 0 AND force_active = 0;

UPDATE
  users_export,
  (
    SELECT
      users.id id,
      IF(users_settings.email_goodie, users.name, SHA2(LOWER(users.name), 256)) name,
      IF(users_settings.email_goodie, users.email, "") email
    FROM users
    JOIN users_settings ON users_settings.user_id = users.id
  ) AS users_privatized
SET
  users_export.name = users_privatized.name,
  users_export.email = users_privatized.email
WHERE
  users_export.id = users_privatized.id
;
