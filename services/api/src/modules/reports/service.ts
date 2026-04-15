export function reportPenalty(openReports: number): number {
  return Math.min(openReports * 0.14, 0.56);
}
