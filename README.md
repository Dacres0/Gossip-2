# Gossip-2

# Gossip
Gossip is a location-based, anonymous social discovery game built around short-lived “bubbles” placed on a shared map. Users drop bubbles at their real-world location to share gossip, discoveries, observations, or recommendations.

Players nearby can view, interact with, upvote or downvote gossip bubbles, influencing their credibility score. The system promotes highly rated bubbles whilst unreliable ones dissapear.

Businesses can also participate by placing promotional gossip bubbles, allowing the community to validate promotions through votes. Instead of usual marketing where companies can make stuff up, this is a unique style of marketing where its 100% based on the community and how good the product is.

The game is a combination of elements including:

- Social media
- Location based interaction
- Reputation systems
- Community driven storytelling

 ## User and System Requirements (Scrum Stories)

Primary users include:

- Players, anonymous users interaction with gossip bubbles
- Businesses, organisations promoting themselves
- System administrators, Maintain platform moderation and integrity 

# User Requirements
Anonymous Participation

Story "As a player, i want to post gossip anonymously so that i can share information without revealing my identity".

Priority: High 

Requirements

- No personal identity required
- Temporary user ID generated
- Privacy protection

# Location-Based interaction

Story "As a player, i want to see gossip bubbles near my location so that i can discover local stories and rumours".

Priority: High 

Requirements 

- GPS integration
- Map interface
- Proximity Filtering 

# Voting System

Story "As a player, i want to upvote or downvote gossip bubbles so that credible information rises to the top".

Priority: High

Requirements 

- Upvote system
- Downvote system
- Credibility score calculation

# Gossip Creation

Story "As a player, i want to p[lace a gossip bubble at my current location so that others nearby can see it".

Priority: High

Requirements

- Bubble creation UI
- Text input
- Map placement

# Business Promotion

Story "As a business owner, i want to place promotional bubbles so that local players can discover my business".

Priority: Medium

Requirements 

- Business accounts
- Promotional bubble tagging
- Community voting 

# System Requirements 
Map System

- GPS integration
- Real-time location updates
- Map visualization

Database Stores

- Gossip bubbles
- Votes
- User sessions
- Locations

Moderation

- Filtering offensive content
- Reporting system
- Automatic moderation rules

# Scrum Product Backlog 
| Priority | Feature                 | Description                     | Acceptance Test                                 | Justification                          |
| -------- | ----------------------- | ------------------------------- | ----------------------------------------------- | -------------------------------------- |
| 1        | User Location Detection | Detect user location using GPS  | Location detected within 5 seconds              | Core feature required for all gameplay |
| 2        | Map Display             | Interactive map showing bubbles | Map loads within 2 seconds with visible bubbles | Essential for user interaction         |
| 3        | Create Gossip Bubble    | User posts bubble               | Bubble appears at correct coordinates instantly | Core gameplay mechanic                 |
| 4        | Voting System           | Upvote/downvote bubbles         | Score updates in real-time                      | Drives credibility system              |
| 5        | Credibility Algorithm   | Calculates bubble ranking       | High-score bubbles appear first                 | Ensures quality control                |
| 6        | Anonymous Identity      | Generate temp ID                | No personal data required                       | Supports privacy                       |
| 7        | Bubble Feed             | Nearby bubble list              | Feed refreshes when location changes            | Improves accessibility                 |
| 8        | Business Promotion      | Promotional bubbles             | Tagged and voteable                             | Monetisation feature                   |
| 9        | Moderation Tools        | Report content                  | Reports logged and flagged                      | Prevents abuse                         |
| 10       | Bubble Expiration       | Remove old bubbles              | Bubble deleted after 24 hours                   | Keeps content fresh                    |


 # Game Design and Development 
Game Concept

Gossip is designed to simulate the spread of rumours and social information within a community

Players explore their environment while discovering and contributing to local gossip

The game blends:
- Exploration
- Social interaction
- Reputation mechanics

# Design Justification 
The app was designed with a focus on anonymity, engagement and trust

- Anonymous system was chosen to encourage open sharing without social pressure, increasing user participation
- The voting mechanism ensures community-driven moderation, reducing reliance on central control
- A location-based map interface enhances immersion and encourages real-world exploration
- The bubble expiration system prevents outdated or irrelevant content from cluttering the platform
- Flutter was selected for cross-platform development efficiency, allowing deployment on both Android and iOS from a single codebase
- Firebase was chosen due to its real-time database capabilities, which support instant updates for votes and bubble visibility



# State diagram
<img width="414" height="737" alt="image" src="https://github.com/user-attachments/assets/c42f130b-d425-4fc6-bac0-b87037cbfe25" />

This diagram represents the lifecycle of a gossip bubble, from creation through interaction, scoring, promotion and eventual expiration.

# System Architecture Diagram 
<img width="279" height="402" alt="image" src="https://github.com/user-attachments/assets/b3ba3c86-9ae5-481a-8251-61bf37717b57" />

This diagram illustrates how the mobile application communicates with the backed API and database to manage real time gossip data and user interactions.
# Gameplay

Core Loop
- Player moves around the map
- Player discovers gossip bubbles
- Player reads gossip
- Player votes or responds
- Player creates new gossip
- Community validates gossip

Player Motivation Loop

| Player State | Need               | Action            | Reward      |
| ------------ | ------------------ | ----------------- | ----------- |
| Curious      | Discover gossip    | Explore map       | New content |
| Social       | Share information  | Create gossip     | Engagement  |
| Competitive  | Gain credibility   | Write good gossip | Upvotes     |
| Explorer     | Find hidden gossip | Move location     | Discovery   |

# Game Environment
The game world is based on real-world geography.

Players interact through a map interface representing:

- Streets
- Businesses
- Public locations

Each location can contain multiple gossip bubbles

# Bubble System
Each bubble contains:

- Text message
- Location coordinates
- Vote score
- Timestamp
- Creator ID (anonymous)

# Bubble Lifecycle

- Bubble created
- Bubble appears on map
- Users interact
- Credibility score updated
- Bubble promoted or buried
- Bubble expires

# Game Rules
- Users remain anonymous
- Players can only post bubbles within their GPS radius
- Voting affects credibility
- Offensive content can be reported
- Old bubbles expire

# Characters
The game has no traditional characters

Instead, the community itself acts as the storyteller

Players become:

- Informants
- Investigators
- Observers

# Levels
The game uses geographic progression rather than levels

Players explore:

- Streets
- Universities
- Shopping centres
- Restaurants
- Parks

Each area contains different gossip density
  
# Artwork
Visual Style

Minimalist UI with:

- Map-based design
- Speech bubble icons
- Color-coded credibility scores

| Bubble Type      | Color |
| ---------------- | ----- |
| High credibility | Green |
| Neutral          | Grey  |
| Low credibility  | Red   |

# Sound Design

Optional sound effects:

- Bubble pop when opening gossip
- Vote sound feedback
- Notification sound for new gossip nearby

# User Interface
Main Screens

- Map Screen
- Create Gossip Screen
- Bubble Feed
- Business Promotion Panel

# Controls

Mobile interface:

- Tap to open bubble
- Swipe to navigate feed
- Tap button to create gossip
- Tap arrows to vote

# Programming Language & Platform
Platform
Mobile Application

Potential frameworks:

- Flutter
- React Native
- Native Android (Kotlin)
- Native iOS (Swift)

# Backend

Possible stack:

- Node.js
- Firebase
- MongoDB

# AI / Algorithm Challenges
Credibility Algorithm

The credibility score could be calculated using:

Score = Upvotes − Downvotes

Advanced version may include:

- Time decay
- Vote weighting
- Anti-spam detection

# Pseudo code

# Credibility Score Calculation 

function calculateScore(upvotes, downvotes):
    score = upvotes - downvotes

    if score > 10:
        status = "Promoted"
    else if score < -5:
        status = "Hidden"
    else:
        status = "Neutral"

    return score, status

# Bubble Vissibility 

function getNearbyBubbles(userLocation):
    bubbles = getAllBubbles()
    nearbyBubbles = []

    for bubble in bubbles:
        distance = calculateDistance(userLocation, bubble.location)

        if distance <= 500:
            nearbyBubbles.append(bubble)

    return nearbyBubbles

# Technical Challenges

GPS Accuracy
- Handling inaccurate or spoofed location data

Moderation
- Preventing abuse while maintaining anonymity

Scalability
- Handling thousands of bubbles in urban areas

# Testing Plan
Testing ensures system reliability and functionality


# issues encountered and Resolutions 
GPS Delay Issue
Problem: Slight delay in updating nearby bubbles when the user moved location

Solution: Optimised refresh intervals and reduced unnecessary location checks

Performance Lag
Problem: Slow loading when multiple bubbles were present

Solution: Improved database queries and reduced data load per request

UI Bugs
Problem: Minor interface inconsistencies during bubble creation

Solution: Refined layout and improved input validation
Test Types

Unit Testing
- Testing individual components

Integration Testing
- Testing interaction between systems

User Testing
- Testing with real players

# Test Case
| Test Case       | Requirement       | Expected Result          | Actual Result   | Status   |
| --------------- | ----------------- | ------------------------ | --------------- | -------- |
| Create bubble   | Gossip creation   | Bubble appears instantly | Works correctly | Pass     |
| Upvote bubble   | Voting system     | Score increases by 1     | Works correctly | Pass     |
| Downvote bubble | Voting system     | Score decreases by 1     | Works correctly | Pass     |
| Move location   | Map system        | New bubbles appear       | Slight delay    | Improved |
| Expired bubble  | Expiration system | Bubble removed after 24h | Works correctly | Pass     |

Testing Evaluation

The testing showed that the core features function reliabily, minor delays occured in map update due to GPS refresh rate and performance improvements were implemented to resolve lag. 

# Test Logs
| Date   | Feature         | Result |
| ------ | --------------- | ------ |
| 12 Mar | Bubble creation | Passed |
| 13 Mar | Voting system   | Passed |
| 14 Mar | Map loading     | Passed |

# Project Management
Development Methodology 

- The project uses Scrum Agile Methodology
- The development occurs in short sprints

# Sprint Structure
Sprint length:

- 1–2 weeks

Each sprint includes:

- Planning
- Development
- Testing
- Review

# Burndown Chart
A burndown chart tracks remaining work across a sprint

| Week   | Tasks Remaining |
| ------ | --------------- |
| Week 1 | 20              |
| Week 2 | 12              |
| Week 3 | 5               |
| Week 4 | 0               |

# Backlog Reviews
Backlog is reviewed regularly to:

- Prioritise features
- Adjust workload
- Improve development flow

# Development Meetings
Weekly standups

Meeting Questions

- What did you do since the last meeting?
- What will you work on next?
- What problems are blocking progress?

# Development Log 
| Date   | Work Completed            | Next Task       | Issues          |
| ------ | ------------------------- | --------------- | --------------- |
| Mar 10 | Map UI created            | Bubble creation | GPS accuracy    |
| Mar 11 | Voting system implemented | Backend API     | None            |
| Mar 12 | Database setup            | Testing         | Slow queries    |
| Mar 13 | Bubble creation complete  | UI improvements | Minor UI bugs   |
| Mar 14 | Testing completed         | Optimisation    | Performance lag |


# Software tools and techniques 
Development Tools 

| Tool     | Purpose            |
| -------- | ------------------ |
| Git      | Version control    |
| GitHub   | Repository hosting |
| VS Code  | Development IDE    |
| Flutr    | UI design          |
| Firebase | Backend services   |

# Coding Techniques
The project uses:

- Modular programming
- MVC architecture
- API-based backend
- Asynchronous programming

# Version Control

Git is used to manage code versions.

Key practices:
- Feature branches
- Pull requests
-  Commit history

# Mobile APP wireframes 
<img width="1536" height="1024" alt="d4ee515d-fd7f-4ac9-b3a8-bdd3a4c0bfee" src="https://github.com/user-attachments/assets/5cb2f619-1bb1-4a0e-a1e4-ecdb036c3363" />

# Future improvements 

# Basic and Premium User Model
Introduce a tiered system where basic users have limited access to features, such as viewing a restricted number of gossip bubbles per day. Premium users could access additional content, including exclusive or high-credibility bubbles, supporting potential monetisation of the platform.

# Content Visibility Controls
Premium-only bubbles could be introduced, allowing certain content to be restricted to specific user groups. This would enable differentiated experiences and incentivise upgrades.

# No-Gossip Zones
Implement location-based restrictions where gossip cannot be posted or viewed in sensitive areas such as schools or private institutions. This would improve ethical compliance and protect vulnerable environments.

# Age-Restricted Content
Introduce content filtering using keyword detection to assign age ratings to gossip bubbles. Users would be required to verify their age to access certain categories of content, ensuring safer user interaction.

# Enhanced Interaction Features
Expand user interaction by allowing players to:

- Vote on whether gossip is true or false, in addition to upvotes/downvotes
- Comment on gossip bubbles to encourage discussion and community engagement

# User Reputation System
Develop a reputation system where users gain credibility based on the accuracy and popularity of their contributions. Higher reputation users would have increased influence, improving trust and content quality across the platform.

These improvements would enhance user engagement, platform safety, and the overall reliability of community-driven content.

# Conclusion 
Gossip aims to create a community-driven location-based social game where players interact with anonymous content tied to real-world locations. Through a combination of map exploration, social voting, and community storytelling, the platform encourages players to engage with their surroundings in a unique and dynamic way. The system successfully meets all defined user and system requirements, demonstrating a scalable, user-driven platform supported by real-time interaction and community validation.

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

# Extended Testing

## Extended Testing & Edge Cases

| Test Case | Description | Expected Result | Status |
|----------|------------|----------------|--------|
| Invalid bubble text | User submits empty bubble | Error message shown | Pass |
| No GPS signal | Location unavailable | App shows fallback or error | Pass |
| Rapid voting | Multiple votes quickly | System handles without crash | Pass |
| High bubble density | Many bubbles nearby | Map remains responsive | Pass |
| Expired bubble | After 24 hours | Bubble is removed | Pass |
| Report feature | User reports content | Report is logged | Pass |
| Network failure | Internet disconnects | Graceful error handling | Pass |
| Duplicate bubbles | Same content spam | System still functions correctly | Pass |

# Key strengths

Strong core gameplay loop
Effective use of community moderation
Scalable architecture using Firebase
Structured Agile development process

The project demonstrates a complete system that aligns with all defined requirements, supported by testing, documentation, and iterative improvement.

# User stories 

## User Stories

| ID | User Story |
|----|-----------|
| US1 | As a user, I want my location to be detected automatically so that I can see nearby gossip bubbles |
| US2 | As a user, I want to create a gossip bubble so that I can share information with others nearby |
| US3 | As a user, I want to upvote or downvote bubbles so that I can influence their credibility |
| US4 | As a user, I want to view bubbles on a map so that I can explore content geographically |
| US5 | As a user, I want to remain anonymous so that I can share content without revealing my identity |
| US6 | As a user, I want old bubbles to expire so that the content remains relevant |
| US7 | As a user, I want to report inappropriate content so that the platform remains safe |
# references 

https://www.youtube.com/watch?v=MOqozQAS2VE
Premium free course, learning flutter 

https://www.youtube.com/watch?v=5xU5WH2kEc0
Mitch KOKO- minimal chat app

I used my experience with flutter for my chat app with the combination of these two videos to help me build my location based flutter app.
