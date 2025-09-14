-- Sample Data and Common Queries for Journal System Database

-- Insert sample users
INSERT INTO users (email, first_name, last_name, password_hash, user_type, institution, bio, expertise_areas) VALUES
('john.author@university.edu', 'John', 'Smith', '$2y$10$example_hash_1', 'author', 'University of Science', 'Research scientist in computer science', 'machine learning, artificial intelligence'),
('jane.editor@journal.com', 'Jane', 'Wilson', '$2y$10$example_hash_2', 'editor', 'Academic Publishing House', 'Senior editor with 10 years experience', 'computer science, data science'),
('bob.reviewer@tech.edu', 'Bob', 'Johnson', '$2y$10$example_hash_3', 'reviewer', 'Tech Institute', 'Professor of Computer Science', 'machine learning, neural networks'),
('alice.reviewer@ai.org', 'Alice', 'Brown', '$2y$10$example_hash_4', 'reviewer', 'AI Research Center', 'AI researcher and consultant', 'deep learning, computer vision'),
('mike.editor@science.pub', 'Mike', 'Davis', '$2y$10$example_hash_5', 'editor', 'Science Publications', 'Associate editor', 'data mining, algorithms');

-- Insert sample journals
INSERT INTO journals (journal_name, journal_code, description, issn, publisher, subject_areas) VALUES
('Journal of Computer Science Research', 'JCSR', 'Leading journal in computer science research', '1234-5678', 'Academic Press', 'computer science, artificial intelligence, machine learning'),
('International Journal of Data Science', 'IJDS', 'Premier journal for data science publications', '2345-6789', 'Tech Publications', 'data science, big data, analytics');

-- Insert journal editors
INSERT INTO journal_editors (journal_id, editor_id, role) VALUES
(1, 2, 'chief_editor'),
(1, 5, 'associate_editor'),
(2, 2, 'associate_editor');

-- Insert sample submissions
INSERT INTO submissions (manuscript_id, title, abstract, keywords, author_id, journal_id, manuscript_file_path, current_status, current_round) VALUES
('JCSR-2024-001', 'Deep Learning Approaches for Natural Language Processing', 'This paper presents novel deep learning methods for improving natural language processing tasks...', 'deep learning, NLP, neural networks', 1, 1, '/uploads/manuscripts/jcsr_2024_001.pdf', 'under_peer_review', 1),
('JCSR-2024-002', 'Machine Learning in Healthcare: A Comprehensive Review', 'A systematic review of machine learning applications in healthcare systems...', 'machine learning, healthcare, medical AI', 1, 1, '/uploads/manuscripts/jcsr_2024_002.pdf', 'revision_requested', 1),
('IJDS-2024-001', 'Big Data Analytics for Smart Cities', 'This study explores the use of big data analytics in smart city applications...', 'big data, smart cities, analytics', 1, 2, '/uploads/manuscripts/ijds_2024_001.pdf', 'submitted', 1);

-- Insert submission history
INSERT INTO submission_history (submission_id, previous_status, new_status, changed_by_user_id, comments, round_number) VALUES
(1, 'submitted', 'under_initial_review', 2, 'Initial review started', 1),
(1, 'under_initial_review', 'assigned_to_reviewers', 2, 'Assigned to peer reviewers', 1),
(1, 'assigned_to_reviewers', 'under_peer_review', 2, 'Reviews in progress', 1),
(2, 'submitted', 'under_initial_review', 2, 'Initial review started', 1),
(2, 'under_initial_review', 'assigned_to_reviewers', 2, 'Assigned to reviewers', 1),
(2, 'assigned_to_reviewers', 'revision_requested', 2, 'Reviewers requested revisions', 1);

-- Insert submission editors
INSERT INTO submission_editors (submission_id, editor_id, role, assignment_status) VALUES
(1, 2, 'handling_editor', 'active'),
(2, 5, 'handling_editor', 'active'),
(3, 2, 'handling_editor', 'active');

-- Insert submission reviewers
INSERT INTO submission_reviewers (submission_id, reviewer_id, assigned_by_editor_id, due_date, review_status, review_round, recommendation, review_comments) VALUES
(1, 3, 2, DATE_ADD(NOW(), INTERVAL 30 DAY), 'completed', 1, 'minor_revision', 'The paper is well-written but needs minor improvements in methodology section.'),
(1, 4, 2, DATE_ADD(NOW(), INTERVAL 30 DAY), 'in_progress', 1, NULL, NULL),
(2, 3, 5, DATE_ADD(NOW(), INTERVAL 30 DAY), 'completed', 1, 'major_revision', 'Significant revisions needed in the literature review and analysis sections.'),
(3, 4, 2, DATE_ADD(NOW(), INTERVAL 30 DAY), 'invited', 1, NULL, NULL);

-- Insert sample chat messages
INSERT INTO chat_messages (submission_id, sender_id, recipient_id, message_type, subject, message_content, message_round) VALUES
(1, 2, 1, 'editor_to_author', 'Review Status Update', 'Your submission has been sent for peer review. You should receive feedback within 4-6 weeks.', 1),
(1, 1, 2, 'author_to_editor', 'Question about Review Process', 'Thank you for the update. Could you please clarify the expected timeline for the review process?', 1),
(2, 5, 1, 'editor_to_author', 'Revision Required', 'Based on reviewer feedback, we are requesting revisions to your manuscript. Please see attached reviewer comments.', 1),
(1, 3, 2, 'reviewer_to_editor', 'Review Completed', 'I have completed my review of manuscript JCSR-2024-001. The review has been submitted through the system.', 1);

-- =====================================
-- COMMON QUERIES FOR THE SYSTEM
-- =====================================

-- 1. Get all submissions for a specific author
SELECT 
    s.manuscript_id,
    s.title,
    s.current_status,
    s.submission_date,
    j.journal_name,
    s.current_round
FROM submissions s
JOIN journals j ON s.journal_id = j.journal_id
WHERE s.author_id = 1
ORDER BY s.submission_date DESC;

-- 2. Get all active review assignments for a reviewer
SELECT 
    s.manuscript_id,
    s.title,
    sr.assigned_date,
    sr.due_date,
    sr.review_status,
    j.journal_name
FROM submission_reviewers sr
JOIN submissions s ON sr.submission_id = s.submission_id
JOIN journals j ON s.journal_id = j.journal_id
WHERE sr.reviewer_id = 3 
AND sr.review_status IN ('invited', 'accepted', 'in_progress')
ORDER BY sr.due_date;

-- 3. Get all submissions assigned to an editor
SELECT 
    s.manuscript_id,
    s.title,
    s.current_status,
    s.submission_date,
    CONCAT(u.first_name, ' ', u.last_name) as author_name,
    j.journal_name
FROM submissions s
JOIN submission_editors se ON s.submission_id = se.submission_id
JOIN users u ON s.author_id = u.user_id
JOIN journals j ON s.journal_id = j.journal_id
WHERE se.editor_id = 2 
AND se.assignment_status = 'active'
ORDER BY s.submission_date DESC;

-- 4. Get chat message history for a submission
SELECT 
    cm.message_id,
    CONCAT(sender.first_name, ' ', sender.last_name) as sender_name,
    CASE 
        WHEN cm.recipient_id IS NULL THEN 'All Parties'
        ELSE CONCAT(recipient.first_name, ' ', recipient.last_name)
    END as recipient_name,
    cm.message_type,
    cm.subject,
    cm.message_content,
    cm.sent_date,
    cm.message_round
FROM chat_messages cm
JOIN users sender ON cm.sender_id = sender.user_id
LEFT JOIN users recipient ON cm.recipient_id = recipient.user_id
WHERE cm.submission_id = 1
ORDER BY cm.sent_date;

-- 5. Get submission status history
SELECT 
    sh.history_id,
    sh.previous_status,
    sh.new_status,
    CONCAT(u.first_name, ' ', u.last_name) as changed_by,
    sh.change_date,
    sh.comments,
    sh.round_number
FROM submission_history sh
JOIN users u ON sh.changed_by_user_id = u.user_id
WHERE sh.submission_id = 1
ORDER BY sh.change_date;

-- 6. Get overdue reviews
SELECT 
    s.manuscript_id,
    s.title,
    CONCAT(r.first_name, ' ', r.last_name) as reviewer_name,
    r.email as reviewer_email,
    sr.assigned_date,
    sr.due_date,
    DATEDIFF(NOW(), sr.due_date) as days_overdue
FROM submission_reviewers sr
JOIN submissions s ON sr.submission_id = s.submission_id
JOIN users r ON sr.reviewer_id = r.user_id
WHERE sr.due_date < NOW() 
AND sr.review_status IN ('invited', 'accepted', 'in_progress')
ORDER BY sr.due_date;

-- 7. Get journal statistics
SELECT 
    j.journal_name,
    COUNT(s.submission_id) as total_submissions,
    SUM(CASE WHEN s.current_status = 'accepted' THEN 1 ELSE 0 END) as accepted,
    SUM(CASE WHEN s.current_status = 'rejected' THEN 1 ELSE 0 END) as rejected,
    SUM(CASE WHEN s.current_status IN ('submitted', 'under_initial_review', 'assigned_to_reviewers', 'under_peer_review', 'revision_requested', 'revised_submitted') THEN 1 ELSE 0 END) as in_progress,
    ROUND(AVG(DATEDIFF(COALESCE(s.decision_date, NOW()), s.submission_date)), 1) as avg_processing_days
FROM journals j
LEFT JOIN submissions s ON j.journal_id = s.journal_id
GROUP BY j.journal_id, j.journal_name;

-- 8. Get reviewer workload
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) as reviewer_name,
    u.email,
    COUNT(sr.review_assignment_id) as total_assignments,
    SUM(CASE WHEN sr.review_status = 'completed' THEN 1 ELSE 0 END) as completed_reviews,
    SUM(CASE WHEN sr.review_status IN ('accepted', 'in_progress') THEN 1 ELSE 0 END) as active_reviews,
    SUM(CASE WHEN sr.review_status = 'declined' THEN 1 ELSE 0 END) as declined_reviews
FROM users u
LEFT JOIN submission_reviewers sr ON u.user_id = sr.reviewer_id
WHERE u.user_type = 'reviewer'
GROUP BY u.user_id, u.first_name, u.last_name, u.email
ORDER BY active_reviews DESC, completed_reviews DESC;

-- 9. Get submissions requiring action (for editors)
SELECT 
    s.manuscript_id,
    s.title,
    s.current_status,
    s.submission_date,
    CONCAT(u.first_name, ' ', u.last_name) as author_name,
    CASE 
        WHEN s.current_status = 'submitted' THEN 'Needs initial review'
        WHEN s.current_status = 'under_initial_review' THEN 'Assign reviewers'
        WHEN s.current_status = 'under_peer_review' THEN 'Awaiting reviews'
        WHEN s.current_status = 'revised_submitted' THEN 'Review revisions'
        ELSE 'No action needed'
    END as action_required
FROM submissions s
JOIN users u ON s.author_id = u.user_id
JOIN submission_editors se ON s.submission_id = se.submission_id
WHERE se.editor_id = 2 
AND se.assignment_status = 'active'
AND s.current_status IN ('submitted', 'under_initial_review', 'revised_submitted')
ORDER BY s.submission_date;

-- 10. Get recent activity feed
SELECT 
    'submission' as activity_type,
    s.manuscript_id as reference_id,
    CONCAT('New submission: ', s.title) as activity_description,
    CONCAT(u.first_name, ' ', u.last_name) as user_name,
    s.submission_date as activity_date
FROM submissions s
JOIN users u ON s.author_id = u.user_id
WHERE s.submission_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)

UNION ALL

SELECT 
    'status_change' as activity_type,
    s.manuscript_id as reference_id,
    CONCAT('Status changed to: ', sh.new_status) as activity_description,
    CONCAT(u.first_name, ' ', u.last_name) as user_name,
    sh.change_date as activity_date
FROM submission_history sh
JOIN submissions s ON sh.submission_id = s.submission_id
JOIN users u ON sh.changed_by_user_id = u.user_id
WHERE sh.change_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)

UNION ALL

SELECT 
    'review_completed' as activity_type,
    s.manuscript_id as reference_id,
    CONCAT('Review completed with recommendation: ', sr.recommendation) as activity_description,
    CONCAT(u.first_name, ' ', u.last_name) as user_name,
    sr.review_submitted_date as activity_date
FROM submission_reviewers sr
JOIN submissions s ON sr.submission_id = s.submission_id
JOIN users u ON sr.reviewer_id = u.user_id
WHERE sr.review_submitted_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)

ORDER BY activity_date DESC
LIMIT 20;