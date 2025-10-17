export const toError = (error: unknown): Error => {
  if (error instanceof Error) {
    return error;
  }
  if (typeof error === 'string') {
    return new Error(error);
  }
  try {
    return new Error(JSON.stringify(error));
  } catch {
    return new Error('Unknown error');
  }
};

export const extractDateTime = (
  value: { dateTime?: string; date?: string }
): { dateTime: string; allDay: boolean } => {
  if (value.dateTime) {
    return { dateTime: value.dateTime, allDay: false };
  }
  if (value.date) {
    return { dateTime: value.date, allDay: true };
  }
  return { dateTime: new Date().toISOString(), allDay: false };
};
