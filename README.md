# Citizen Science Platform Smart Contract

## Overview

This Clarity smart contract provides a decentralized platform for citizen science projects, enabling researchers to create projects, define tasks, and reward participants for their contributions on the Stacks blockchain.

## Key Features

- Project and task management
- Decentralized data collection
- Contribution tracking
- Reward mechanism with native fungible token
- Permissioned task creation and validation

## Contract Components

### Constants
- `contract-owner`: Initial deployer of the contract
- Error constants for access control and validation

### Data Variables
- `project-id-nonce`: Tracks total number of created projects
- `task-id-nonce`: Tracks total number of created tasks

### Data Maps
- `projects`: Stores project details
- `tasks`: Manages individual task information
- `project-tasks`: Links projects to their associated tasks
- `user-contributions`: Tracks user submissions for tasks
- `user-rewards`: Manages user reward balances

### Fungible Token
- `citizen-science-token`: Native token for rewarding contributors

## Primary Functions

### Project Management
`create-project(name, description, institution)`
- Creates a new citizen science project
- Restricted to contract owner
- Returns unique project ID

### Task Management
`create-task(project-id, description, reward)`
- Adds a new task to an existing project
- Restricted to project's associated institution
- Returns unique task ID

### Contribution Workflow
`submit-data(task-id, data)`
- Allows users to submit data for an open task
- Stores user contribution

`validate-data(task-id, user)`
- Project institution validates user contributions
- Marks task as completed
- Distributes rewards via fungible tokens

## Read-Only Functions

- `get-project(project-id)`: Retrieve project details
- `get-task(task-id)`: Retrieve task details
- `get-project-tasks(project-id)`: List tasks for a project
- `get-user-contribution(user, task-id)`: Fetch user's task submission
- `get-user-rewards(user)`: Check user's reward balance

## Usage Example

```clarity
;; Create a citizen science project
(create-project 
  "Climate Change Observation" 
  u"Collect local temperature and weather data" 
  contract-owner
)

;; Create a task for the project
(create-task u1 u"Record daily temperature" u100)

;; Submit scientific observation
(submit-data u1 u"Temperature: 22.5°C, Humidity: 65%")

;; Validate and reward contribution
(validate-data u1 tx-sender)
```

## Error Handling

The contract uses custom error codes:
- `u100`: Owner-only access
- `u101`: Resource not found
- `u102`: Resource already exists

## Access Control
- Project creation restricted to contract owner
- Task creation restricted to project's associated institution
- Data validation restricted to project institution

## Token Economics
- Contributors earn `citizen-science-token` for validated contributions
- Reward amount defined per task

## Security Considerations
- Permissioned task creation and validation
- Contribution tracking
- Controlled token distribution

## Dependencies
- Stacks blockchain
- Clarity smart contract language

## Contributing
1. Review contract implementation
2. Test thoroughly
3. Submit pull requests with detailed descriptions

## License
[Insert appropriate open-source license]

## Contact
[Project maintainer contact information]
