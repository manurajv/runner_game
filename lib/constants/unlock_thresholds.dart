enum UnlockLevel {
  profile,
  skills,
  education,
  experience,
  projects,
  achievements,
}

const Map<UnlockLevel, int> unlockThresholds = {
  UnlockLevel.profile: 100,
  UnlockLevel.skills: 250,
  UnlockLevel.education: 500,
  UnlockLevel.experience: 800,
  UnlockLevel.projects: 1200,
  UnlockLevel.achievements: 1500,
};


