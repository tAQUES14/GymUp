class PointsService {
  PointsService();

  // This service can be used for more complex point logic if needed,
  // currently most logic is handled transactionally in FirestoreService
  // but it's good practice to have a dedicated service for business logic.

  // Example: Calculate level based on points
  String getLevel(int points) {
    if (points < 100) return 'Iniciante';
    if (points < 500) return 'Intermediário';
    if (points < 1000) return 'Avançado';
    return 'Mestre';
  }
}
