# Gossip 2
# Scrum Product Backlog 

| Priority | Feature                 | Definition                                             | Acceptance Test                                                                    | Evaluation / Justification                                          |
| -------- | ----------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1        | User Location Detection | The system retrieves the user’s real-time GPS location | Location is detected within ≤5 seconds and updated dynamically when the user moves | Critical to all gameplay; without location, the app cannot function |
| 2        | Map Display             | Interactive map showing nearby gossip bubbles          | Map loads in ≤2 seconds and displays bubbles within a 500m radius                  | Ensures usability and supports exploration gameplay                 |
| 3        | Create Gossip Bubble    | Users can create a bubble tied to their location       | Bubble appears instantly at correct coordinates with correct text                  | Core mechanic; must be responsive for engagement                    |
| 4        | Voting System           | Users can upvote/downvote bubbles                      | Score updates in real time across all users                                        | Drives credibility and community moderation                         |
| 5        | Credibility Algorithm   | Calculates bubble ranking using votes                  | High-score bubbles appear more prominently than low-score ones                     | Ensures quality control and reduces misinformation                  |
| 6        | Anonymous Identity      | System assigns temporary user IDs                      | No personal data is stored; IDs reset periodically                                 | Supports privacy and encourages participation                       |
| 7        | Bubble Feed             | Displays list of nearby bubbles                        | Feed refreshes when location changes or new bubbles appear                         | Improves accessibility beyond map interaction                       |
| 8        | Business Promotion      | Businesses create promotional bubbles                  | Promotional bubbles are tagged and voteable                                        | Enables monetisation while remaining community-driven               |
| 9        | Moderation Tools        | Users can report inappropriate content                 | Reports are logged and flagged automatically                                       | Prevents abuse and improves safety                                  |
| 10       | Bubble Expiration       | Removes old bubbles automatically                      | Bubbles delete after 24 hours                                                      | Keeps content relevant and reduces clutter                          |

# Design, Development & Implementation Updates

# Design Changes
Improved UI layout for bubble creation (fixed alignment issues)
Introduced colour-coded credibility system (green, grey, red)
Added bubble expiration logic for content freshness

# Development Updates
Optimised GPS refresh rate to reduce delay
Improved database queries to handle high bubble density
Implemented asynchronous updates for real-time voting
Implementation Documentation (GitHub ReadMe.md)

All updates are recorded in the repository, including:
Feature additions (e.g., voting system, moderation tools)
Bug fixes (GPS delay, UI inconsistencies)
Performance improvements (database optimisation)

# Project Planning, Management & Documentation

# Backlog Reviews
Conducted weekly
Tasks reprioritised based on progress and issues
Ensured focus on core gameplay features first**

# Burndown chart
| Week   | Tasks Remaining |
| ------ | --------------- |
| Week 1 | 20              |
| Week 2 | 12              |
| Week 3 | 5               |
| Week 4 | 0               |
****

# Development Review Meetings

| Date   | Completed Work            | Next Tasks                | Issues / Barriers |
| ------ | ------------------------- | ------------------------- | ----------------- |
| Mar 10 | Map UI created            | Implement bubble creation | GPS accuracy      |
| Mar 11 | Voting system implemented | Backend API               | None              |
| Mar 12 | Database setup            | Testing                   | Slow queries      |
| Mar 13 | Bubble creation completed | UI improvements           | Minor bugs        |

# Software Tools & Coding Techniques

| Tool     | Purpose                       |
| -------- | ----------------------------- |
| Git      | Version control               |
| GitHub   | Repository & collaboration    |
| VS Code  | Development environment       |
| Flutter  | Cross-platform UI development |
| Firebase | Real-time backend database    |

# Coding Techniques
Modular Programming – Code split into reusable components
MVC Architecture – Separation of logic, UI, and data
Asynchronous Programming – Enables real-time updates
API Integration – Handles communication between frontend and backend

# Evaluation
Flutter reduces development time across platforms
Firebase supports real-time updates required for voting and map data
Git ensures safe version control and rollback capability

# Testing & Validation
| Test Case         | Expected Result    | Actual Result        | Status   |
| ----------------- | ------------------ | -------------------- | -------- |
| Create bubble     | Appears instantly  | Works correctly      | Pass     |
| Upvote bubble     | Score +1           | Works correctly      | Pass     |
| Downvote bubble   | Score -1           | Works correctly      | Pass     |
| Move location     | New bubbles appear | Slight delay (fixed) | Improved |
| Bubble expiration | Deletes after 24h  | Works correctly      | Pass     |

# Conclusion

The Gossip system successfully meets its design objectives by delivering a location-based, anonymous social experience supported by real-time interaction and community validation.

# Key strengths

Strong core gameplay loop
Effective use of community moderation
Scalable architecture using Firebase
Structured Agile development process

The project demonstrates a complete system that aligns with all defined requirements, supported by testing, documentation, and iterative improvement.

# references 

https://www.youtube.com/watch?v=MOqozQAS2VE
Premium free course, learning flutter 

https://www.youtube.com/watch?v=5xU5WH2kEc0
Mitch KOKO- minimal chat app

I used my experience with flutter for my chat app with the combination of these two videos to help me build my location based flutter app.
