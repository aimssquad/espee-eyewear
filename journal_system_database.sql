-- Journal Submission and Review System Database Schema
-- MySQL Database Design

-- Drop existing tables if they exist (in reverse order of dependencies)
DROP TABLE IF EXISTS chat_messages;
DROP TABLE IF EXISTS submission_reviewers;
DROP TABLE IF EXISTS submission_editors;
DROP TABLE IF EXISTS submission_history;
DROP TABLE IF EXISTS submissions;
DROP TABLE IF EXISTS journal_editors;
DROP TABLE IF EXISTS journals;
DROP TABLE IF EXISTS users;

-- Users table (Authors, Editors, Reviewers)
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('author', 'editor', 'reviewer', 'admin') NOT NULL,
    institution VARCHAR(255),
    bio TEXT,
    expertise_areas TEXT, -- JSON or comma-separated list
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_email (email),
    INDEX idx_user_type (user_type),
    INDEX idx_created_at (created_at)
);

-- Journals table
CREATE TABLE journals (
    journal_id INT PRIMARY KEY AUTO_INCREMENT,
    journal_name VARCHAR(255) NOT NULL,
    journal_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    issn VARCHAR(20),
    publisher VARCHAR(255),
    subject_areas TEXT, -- JSON or comma-separated list
    submission_guidelines TEXT,
    review_process_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_journal_code (journal_code),
    INDEX idx_journal_name (journal_name)
);

-- Journal Editors (Many-to-Many relationship between journals and editors)
CREATE TABLE journal_editors (
    journal_editor_id INT PRIMARY KEY AUTO_INCREMENT,
    journal_id INT NOT NULL,
    editor_id INT NOT NULL,
    role ENUM('chief_editor', 'associate_editor', 'guest_editor') DEFAULT 'associate_editor',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (journal_id) REFERENCES journals(journal_id) ON DELETE CASCADE,
    FOREIGN KEY (editor_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_journal_editor (journal_id, editor_id),
    INDEX idx_journal_id (journal_id),
    INDEX idx_editor_id (editor_id)
);

-- Submissions table
CREATE TABLE submissions (
    submission_id INT PRIMARY KEY AUTO_INCREMENT,
    manuscript_id VARCHAR(50) UNIQUE NOT NULL, -- Human-readable ID like "JNL-2024-001"
    title VARCHAR(500) NOT NULL,
    abstract TEXT NOT NULL,
    keywords TEXT,
    author_id INT NOT NULL,
    journal_id INT NOT NULL,
    manuscript_file_path VARCHAR(500), -- Path to uploaded manuscript file
    supplementary_files_path TEXT, -- JSON array of file paths
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    current_status ENUM(
        'submitted',
        'under_initial_review',
        'assigned_to_reviewers',
        'under_peer_review',
        'revision_requested',
        'revised_submitted',
        'accepted',
        'rejected',
        'withdrawn'
    ) DEFAULT 'submitted',
    current_round INT DEFAULT 1, -- Tracks revision rounds
    decision_date TIMESTAMP NULL,
    decision_comments TEXT,
    
    FOREIGN KEY (author_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (journal_id) REFERENCES journals(journal_id) ON DELETE CASCADE,
    INDEX idx_manuscript_id (manuscript_id),
    INDEX idx_author_id (author_id),
    INDEX idx_journal_id (journal_id),
    INDEX idx_current_status (current_status),
    INDEX idx_submission_date (submission_date)
);

-- Submission History (Track all status changes and decisions)
CREATE TABLE submission_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    submission_id INT NOT NULL,
    previous_status ENUM(
        'submitted',
        'under_initial_review',
        'assigned_to_reviewers',
        'under_peer_review',
        'revision_requested',
        'revised_submitted',
        'accepted',
        'rejected',
        'withdrawn'
    ),
    new_status ENUM(
        'submitted',
        'under_initial_review',
        'assigned_to_reviewers',
        'under_peer_review',
        'revision_requested',
        'revised_submitted',
        'accepted',
        'rejected',
        'withdrawn'
    ) NOT NULL,
    changed_by_user_id INT NOT NULL,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comments TEXT,
    round_number INT DEFAULT 1,
    
    FOREIGN KEY (submission_id) REFERENCES submissions(submission_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_submission_id (submission_id),
    INDEX idx_change_date (change_date),
    INDEX idx_changed_by_user (changed_by_user_id)
);

-- Submission Editors (Many-to-Many: Multiple editors can be assigned to a submission)
CREATE TABLE submission_editors (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    submission_id INT NOT NULL,
    editor_id INT NOT NULL,
    role ENUM('handling_editor', 'associate_editor', 'guest_editor') DEFAULT 'handling_editor',
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assignment_status ENUM('active', 'completed', 'declined') DEFAULT 'active',
    notes TEXT,
    
    FOREIGN KEY (submission_id) REFERENCES submissions(submission_id) ON DELETE CASCADE,
    FOREIGN KEY (editor_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_submission_id (submission_id),
    INDEX idx_editor_id (editor_id),
    INDEX idx_assigned_date (assigned_date)
);

-- Submission Reviewers (Many-to-Many: Multiple reviewers per submission)
CREATE TABLE submission_reviewers (
    review_assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    submission_id INT NOT NULL,
    reviewer_id INT NOT NULL,
    assigned_by_editor_id INT NOT NULL,
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP NULL,
    review_status ENUM(
        'invited',
        'accepted',
        'declined',
        'in_progress',
        'completed',
        'overdue'
    ) DEFAULT 'invited',
    review_round INT DEFAULT 1,
    review_file_path VARCHAR(500), -- Path to review document
    recommendation ENUM(
        'accept',
        'minor_revision',
        'major_revision',
        'reject'
    ) NULL,
    review_comments TEXT,
    confidential_comments TEXT, -- Comments only for editors
    review_submitted_date TIMESTAMP NULL,
    
    FOREIGN KEY (submission_id) REFERENCES submissions(submission_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by_editor_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_submission_id (submission_id),
    INDEX idx_reviewer_id (reviewer_id),
    INDEX idx_review_status (review_status),
    INDEX idx_assigned_date (assigned_date),
    INDEX idx_due_date (due_date)
);

-- Chat Messages (Communication between all parties)
CREATE TABLE chat_messages (
    message_id INT PRIMARY KEY AUTO_INCREMENT,
    submission_id INT NOT NULL,
    sender_id INT NOT NULL,
    recipient_id INT NULL, -- NULL for broadcast messages to all parties
    message_type ENUM(
        'author_to_editor',
        'editor_to_author',
        'editor_to_reviewer',
        'reviewer_to_editor',
        'system_notification',
        'general_discussion'
    ) NOT NULL,
    subject VARCHAR(255),
    message_content TEXT NOT NULL,
    sent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    read_date TIMESTAMP NULL,
    message_round INT DEFAULT 1, -- Associates message with revision round
    attachment_paths TEXT, -- JSON array of file paths
    is_system_generated BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (submission_id) REFERENCES submissions(submission_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_submission_id (submission_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_recipient_id (recipient_id),
    INDEX idx_sent_date (sent_date),
    INDEX idx_message_type (message_type),
    INDEX idx_is_read (is_read)
);

-- Create some useful views for common queries

-- View: Active submissions with current assignments
CREATE VIEW active_submissions_overview AS
SELECT 
    s.submission_id,
    s.manuscript_id,
    s.title,
    s.current_status,
    s.current_round,
    s.submission_date,
    CONCAT(u.first_name, ' ', u.last_name) as author_name,
    u.email as author_email,
    j.journal_name,
    COUNT(DISTINCT se.editor_id) as assigned_editors,
    COUNT(DISTINCT sr.reviewer_id) as assigned_reviewers
FROM submissions s
JOIN users u ON s.author_id = u.user_id
JOIN journals j ON s.journal_id = j.journal_id
LEFT JOIN submission_editors se ON s.submission_id = se.submission_id AND se.assignment_status = 'active'
LEFT JOIN submission_reviewers sr ON s.submission_id = sr.submission_id AND sr.review_status IN ('accepted', 'in_progress')
WHERE s.current_status NOT IN ('accepted', 'rejected', 'withdrawn')
GROUP BY s.submission_id, s.manuscript_id, s.title, s.current_status, s.current_round, s.submission_date, u.first_name, u.last_name, u.email, j.journal_name;

-- View: Review assignments with status
CREATE VIEW review_assignments_status AS
SELECT 
    sr.review_assignment_id,
    s.manuscript_id,
    s.title as submission_title,
    CONCAT(r.first_name, ' ', r.last_name) as reviewer_name,
    r.email as reviewer_email,
    CONCAT(e.first_name, ' ', e.last_name) as assigned_by_editor,
    sr.assigned_date,
    sr.due_date,
    sr.review_status,
    sr.recommendation,
    sr.review_round,
    j.journal_name
FROM submission_reviewers sr
JOIN submissions s ON sr.submission_id = s.submission_id
JOIN users r ON sr.reviewer_id = r.user_id
JOIN users e ON sr.assigned_by_editor_id = e.user_id
JOIN journals j ON s.journal_id = j.journal_id
ORDER BY sr.assigned_date DESC;

-- Indexes for better performance
CREATE INDEX idx_submissions_status_date ON submissions(current_status, submission_date);
CREATE INDEX idx_chat_messages_submission_date ON chat_messages(submission_id, sent_date);
CREATE INDEX idx_submission_history_submission_date ON submission_history(submission_id, change_date);