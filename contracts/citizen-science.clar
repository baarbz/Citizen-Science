import { describe, it, expect, beforeEach } from 'vitest'

// Mock contract state
const contractState = {
  projectIdNonce: 0,
  projects: new Map(),
  tasks: new Map(),
  userContributions: new Map(),
  userRewards: new Map(),
}

// Mock contract functions
const contractFunctions = {
  createProject: (name: string, description: string, institution: string) => {
    const projectId = ++contractState.projectIdNonce
    contractState.projects.set(projectId, {
      name,
      description,
      institution,
      status: 'active'
    })
    return { ok: true, value: projectId }
  },

  createTask: (projectId: number, description: string, reward: number) => {
    const project = contractState.projects.get(projectId)
    if (!project) return { ok: false, error: 'Project not found' }

    const taskId = (contractState.tasks.get(projectId)?.size || 0) + 1
    if (!contractState.tasks.has(projectId)) {
      contractState.tasks.set(projectId, new Map())
    }
    contractState.tasks.get(projectId)!.set(taskId, {
      description,
      reward,
      status: 'open'
    })
    return { ok: true, value: true }
  },

  submitData: (projectId: number, taskId: number, user: string, data: string) => {
    const project = contractState.projects.get(projectId)
    const task = contractState.tasks.get(projectId)?.get(taskId)
    if (!project || !task) return { ok: false, error: 'Project or task not found' }
    if (task.status !== 'open') return { ok: false, error: 'Task is not open' }

    const key = `${projectId}-${taskId}-${user}`
    contractState.userContributions.set(key, { data })
    return { ok: true, value: true }
  },

  validateData: (projectId: number, taskId: number, user: string) => {
    const project = contractState.projects.get(projectId)
    const task = contractState.tasks.get(projectId)?.get(taskId)
    if (!project || !task) return { ok: false, error: 'Project or task not found' }

    const key = `${projectId}-${taskId}-${user}`
    const contribution = contractState.userContributions.get(key)
    if (!contribution) return { ok: false, error: 'No contribution found' }

    contractState.tasks.get(projectId)!.set(taskId, { ...task, status: 'completed' })

    const currentReward = contractState.userRewards.get(user) || 0
    contractState.userRewards.set(user, currentReward + task.reward)

    return { ok: true, value: true }
  },

  getProject: (projectId: number) => {
    const project = contractState.projects.get(projectId)
    return project ? { ok: true, value: project } : { ok: false, error: 'Project not found' }
  },

  getTask: (projectId: number, taskId: number) => {
    const task = contractState.tasks.get(projectId)?.get(taskId)
    return task ? { ok: true, value: task } : { ok: false, error: 'Task not found' }
  },

  getUserRewards: (user: string) => {
    return { ok: true, value: { balance: contractState.userRewards.get(user) || 0 } }
  }
}

describe('Citizen Science Smart Contract', () => {
  beforeEach(() => {
    // Reset contract state before each test
    contractState.projectIdNonce = 0
    contractState.projects.clear()
    contractState.tasks.clear()
    contractState.userContributions.clear()
    contractState.userRewards.clear()
  })

  it('should create a new project', () => {
    const result = contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    expect(result.ok).toBe(true)
    expect(result.value).toBe(1)
    expect(contractState.projects.size).toBe(1)
    expect(contractState.projects.get(1)).toEqual({
      name: 'Bird Migration Study',
      description: 'Track bird migration patterns',
      institution: 'institution1',
      status: 'active'
    })
  })

  it('should create a new task', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    const result = contractFunctions.createTask(1, 'Record bird sightings', 10)
    expect(result.ok).toBe(true)
    expect(result.value).toBe(true)
    expect(contractState.tasks.get(1)?.size).toBe(1)
    expect(contractState.tasks.get(1)?.get(1)).toEqual({
      description: 'Record bird sightings',
      reward: 10,
      status: 'open'
    })
  })

  it('should submit data for a task', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    contractFunctions.createTask(1, 'Record bird sightings', 10)
    const result = contractFunctions.submitData(1, 1, 'user1', 'Spotted 5 robins at coordinates 40.7128° N, 74.0060° W')
    expect(result.ok).toBe(true)
    expect(result.value).toBe(true)
    expect(contractState.userContributions.get('1-1-user1')).toEqual({
      data: 'Spotted 5 robins at coordinates 40.7128° N, 74.0060° W'
    })
  })

  it('should validate data and distribute rewards', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    contractFunctions.createTask(1, 1, 'Record bird sightings', 10)
    contractFunctions.submitData(1, 1, 'user1', 'Spotted 5 robins at coordinates 40.7128° N, 74.0060° W')
    const result = contractFunctions.validateData(1, 1, 'user1')
    expect(result.ok).toBe(true)
    expect(result.value).toBe(true)
    expect(contractState.tasks.get(1)?.get(1)?.status).toBe('completed')
    expect(contractState.userRewards.get('user1')).toBe(10)
  })

  it('should get project details', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    const result = contractFunctions.getProject(1)
    expect(result.ok).toBe(true)
    expect(result.value).toEqual({
      name: 'Bird Migration Study',
      description: 'Track bird migration patterns',
      institution: 'institution1',
      status: 'active'
    })
  })

  it('should get task details', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    contractFunctions.createTask(1, 'Record bird sightings', 10)
    const result = contractFunctions.getTask(1, 1)
    expect(result.ok).toBe(true)
    expect(result.value).toEqual({
      description: 'Record bird sightings',
      reward: 10,
      status: 'open'
    })
  })

  it('should get user rewards', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    contractFunctions.createTask(1, 'Record bird sightings', 10)
    contractFunctions.submitData(1, 1, 'user1', 'Spotted 5 robins at coordinates 40.7128° N, 74.0060° W')
    contractFunctions.validateData(1, 1, 'user1')
    const result = contractFunctions.getUserRewards('user1')
    expect(result.ok).toBe(true)
    expect(result.value).toEqual({ balance: 10 })
  })

  it('should handle errors when project is not found', () => {
    const result = contractFunctions.getProject(999)
    expect(result.ok).toBe(false)
    expect(result.error).toBe('Project not found')
  })

  it('should handle errors when task is not found', () => {
    contractFunctions.createProject('Bird Migration Study', 'Track bird migration patterns', 'institution1')
    const result = contractFunctions.getTask(1, 999)
    expect(result.ok).toBe(false)
    expect(result.error).toBe('Task not found')
  })
})

