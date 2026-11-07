import { limits } from '../config.js';
import { matches, AppError } from './validation.js';

export function noteFinding({ job, model, kind, status, issue }) {
  // Metadata only. Never include text, refusal content, SDK errors, or IDs.
  console.warn(JSON.stringify({ event: 'model_attempt_failed', job, model, kind, status, issue }));
}

export async function runText({ client, job, prompt, input, schema, candidates, validate = (value) => value, finding = noteFinding }) {
  for (const model of [...new Set(candidates)]) {
    for (let refusalAttempt = 0; refusalAttempt < 2; refusalAttempt += 1) {
      let phase = 'request';
      try {
        const response = await client.responses.create({
          model,
          reasoning: { effort: 'none' },
          store: false,
          max_output_tokens: limits.outputTokens[job],
          instructions: prompt,
          input: [{ role: 'user', content: [{ type: 'input_text', text: JSON.stringify(input) }] }],
          text: { format: { type: 'json_schema', name: job, strict: true, schema } },
        });
        const content = (response.output || []).filter((item) => item.type === 'message').flatMap((item) => item.content || []);
        if (content.some((item) => item.type === 'refusal')) {
          finding({ job, model, kind: 'refusal' });
          continue;
        }
        if (response.status !== 'completed') {
          finding({ job, model, kind: 'incomplete' });
          break;
        }
        const output = content.filter((item) => item.type === 'output_text');
        phase = 'parse';
        if (output.length !== 1) throw new Error('Invalid model output');
        const value = JSON.parse(output[0].text);
        phase = 'schema';
        if (!matches(value, schema)) throw new Error('Invalid model schema');
        phase = 'postprocess';
        return validate(value);
      } catch (error) {
        const issues = ['task_length', 'task_characters', 'task_private_word', 'task_word_count', 'task_source_overlap', 'empty_reply'];
        finding({ job, model, kind: phase,
          ...(issues.includes(error.outputIssue) ? { issue: error.outputIssue } : {}),
          ...(Number.isInteger(error.status) ? { status: error.status } : {}),
        });
        break;
      }
    }
  }
  throw new AppError(502, 'model_unavailable', 'Aku belum bisa memprosesnya. Kamu bisa coba lagi nanti.');
}
