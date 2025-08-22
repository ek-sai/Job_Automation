-- PostgreSQL Database Setup for N8N Job Application Workflow
-- Run this script in your PostgreSQL database before using the workflow

-- Create the main database
CREATE DATABASE "Jobs";

-- Connect to the database
\c "Jobs";

-- Companies table to store unique companies
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    domain VARCHAR(255),
    industry VARCHAR(255),
    size VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Jobs table to track all processed jobs
CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    location VARCHAR(255),
    job_url TEXT UNIQUE NOT NULL,
    linkedin_job_id VARCHAR(100),
    job_description TEXT,
    match_score INTEGER CHECK (match_score >= 0 AND match_score <= 100),
    status VARCHAR(50) DEFAULT 'discovered', -- discovered, scored, applied, skipped
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Create indexes for jobs table
CREATE INDEX idx_jobs_company_id ON jobs(company_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at);
CREATE INDEX idx_jobs_match_score ON jobs(match_score);

-- Email contacts table to track recruiter/HR contacts
CREATE TABLE email_contacts (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    job_title VARCHAR(200),
    confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
    source VARCHAR(100), -- hunter_hr, hunter_general, manual, linkedin
    is_active BOOLEAN DEFAULT true,
    last_contacted TIMESTAMP,
    contact_count INTEGER DEFAULT 0,
    response_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for email_contacts table
CREATE INDEX idx_email_contacts_company_id ON email_contacts(company_id);
CREATE INDEX idx_email_contacts_email ON email_contacts(email);
CREATE INDEX idx_email_contacts_last_contacted ON email_contacts(last_contacted);

-- Applications table to track sent applications
CREATE TABLE applications (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
    email_contact_id INTEGER REFERENCES email_contacts(id) ON DELETE CASCADE,
    email_address VARCHAR(255) NOT NULL,
    subject VARCHAR(500),
    email_body TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'sent', -- sent, delivered, opened, replied, rejected, no_response
    response_received BOOLEAN DEFAULT false,
    response_date TIMESTAMP,
    response_text TEXT,
    follow_up_needed BOOLEAN DEFAULT false,
    follow_up_date DATE,
    interview_scheduled BOOLEAN DEFAULT false,
    interview_date TIMESTAMP
);

-- Create indexes for applications table
CREATE INDEX idx_applications_job_id ON applications(job_id);
CREATE INDEX idx_applications_email_contact_id ON applications(email_contact_id);
CREATE INDEX idx_applications_sent_at ON applications(sent_at);
CREATE INDEX idx_applications_status ON applications(status);

-- Workflow logs for debugging and monitoring
CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(255),
    execution_id VARCHAR(255),
    node_name VARCHAR(255),
    log_level VARCHAR(20) CHECK (log_level IN ('info', 'warning', 'error', 'debug')),
    message TEXT,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for workflow_logs table
CREATE INDEX idx_workflow_logs_created_at ON workflow_logs(created_at);
CREATE INDEX idx_workflow_logs_level ON workflow_logs(log_level);
CREATE INDEX idx_workflow_logs_workflow_name ON workflow_logs(workflow_name);

-- Useful views for analytics
CREATE VIEW application_summary AS
SELECT 
    c.name as company_name,
    c.industry,
    j.title,
    j.location,
    j.match_score,
    a.sent_at,
    a.status as application_status,
    a.response_received,
    ec.email,
    ec.response_count,
    j.job_url
FROM applications a
JOIN jobs j ON a.job_id = j.id
JOIN companies c ON j.company_id = c.id
JOIN email_contacts ec ON a.email_contact_id = ec.id
ORDER BY a.sent_at DESC;

-- View for daily statistics
CREATE VIEW daily_stats AS
SELECT 
    DATE(j.created_at) as date,
    COUNT(j.id) as jobs_found,
    AVG(j.match_score) as avg_match_score,
    COUNT(CASE WHEN j.match_score >= 75 THEN 1 END) as high_score_jobs,
    COUNT(a.id) as applications_sent,
    COUNT(CASE WHEN a.response_received THEN 1 END) as responses_received
FROM jobs j
LEFT JOIN applications a ON j.id = a.job_id
WHERE j.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(j.created_at)
ORDER BY date DESC;

-- View for company performance
CREATE VIEW company_performance AS
SELECT 
    c.name as company_name,
    COUNT(j.id) as total_jobs_found,
    AVG(j.match_score) as avg_match_score,
    COUNT(a.id) as applications_sent,
    COUNT(CASE WHEN a.response_received THEN 1 END) as responses_received,
    CASE 
        WHEN COUNT(a.id) > 0 THEN 
            ROUND((COUNT(CASE WHEN a.response_received THEN 1 END)::float / COUNT(a.id)) * 100, 2)
        ELSE 0 
    END as response_rate_percent,
    MAX(a.sent_at) as last_application_date
FROM companies c
LEFT JOIN jobs j ON c.id = j.company_id
LEFT JOIN applications a ON j.id = a.job_id
GROUP BY c.id, c.name
HAVING COUNT(j.id) > 0
ORDER BY response_rate_percent DESC, applications_sent DESC;

-- Triggers to automatically update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON companies 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_email_contacts_updated_at 
    BEFORE UPDATE ON email_contacts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to clean old logs (optional - run periodically)
CREATE OR REPLACE FUNCTION clean_old_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM workflow_logs 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Sample data for testing (optional)
INSERT INTO companies (name, domain, industry) VALUES 
('Tech Corp', 'techcorp.com', 'Technology'),
('Data Systems Inc', 'datasystems.com', 'Software'),
('AI Solutions', 'aisolutions.com', 'Artificial Intelligence');

-- Grant permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
