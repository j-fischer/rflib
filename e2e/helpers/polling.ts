export interface PollOptions {
    timeoutMs?: number;
    intervalMs?: number;
    description?: string;
}

// Repeats an async action until the predicate passes. Use for org-side async
// processes (Big Object archiving, platform event consumers) where the UI needs
// to be re-queried, not just re-read.
export async function pollUntil<T>(
    action: () => Promise<T>,
    predicate: (result: T) => boolean,
    { timeoutMs = 120_000, intervalMs = 5_000, description = 'condition' }: PollOptions = {}
): Promise<T> {
    const deadline = Date.now() + timeoutMs;
    let lastResult: T | undefined;
    for (;;) {
        lastResult = await action();
        if (predicate(lastResult)) {
            return lastResult;
        }
        if (Date.now() > deadline) {
            throw new Error(`Timed out after ${timeoutMs}ms waiting for ${description}. Last result: ${lastResult}`);
        }
        await new Promise((resolve) => setTimeout(resolve, intervalMs));
    }
}
