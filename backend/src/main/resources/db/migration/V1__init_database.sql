CREATE TABLE IF NOT EXISTS app_settings (
    id BIGINT NOT NULL AUTO_INCREMENT,
    setting_key VARCHAR(100) NOT NULL,
    setting_value VARCHAR(255),
    PRIMARY KEY (id),
    UNIQUE KEY uk_app_settings_key (setting_key)
);