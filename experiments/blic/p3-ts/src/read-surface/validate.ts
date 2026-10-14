import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

/** One place the instrument's output disagreed with the schema the types came from. */
export interface SchemaViolation {
  /** JSON pointer-ish path into the document, e.g. briefs/12/state. */
  readonly path: string;
  readonly message: string;
}

export interface ValidationResult<T> {
  readonly value: T;
  readonly violations: readonly SchemaViolation[];
}

interface JsonSchemaNode {
  readonly type?: string;
  readonly enum?: readonly string[];
  readonly const?: unknown;
  readonly required?: readonly string[];
  readonly properties?: Readonly<Record<string, JsonSchemaNode>>;
  readonly items?: JsonSchemaNode;
  readonly additionalProperties?: boolean;
  readonly $ref?: string;
}

interface RootSchema extends JsonSchemaNode {
  readonly definitions: Readonly<Record<string, JsonSchemaNode>>;
}

// The schema file is the single source of both the generated types and these checks, so a
// field added to one cannot silently miss the other. Read at runtime rather than bundled:
// the point of the exercise is that the schema stays a readable artifact, not a build input.
const SCHEMA_PATH = join(dirname(dirname(dirname(fileURLToPath(import.meta.url)))), 'schema', 'read-surface.schema.json');

let cached: RootSchema | undefined;

function schema(): RootSchema {
  cached ??= JSON.parse(readFileSync(SCHEMA_PATH, 'utf8')) as RootSchema;
  return cached;
}

function deref(node: JsonSchemaNode): JsonSchemaNode {
  if (node.$ref === undefined) return node;
  const name = node.$ref.replace('#/definitions/', '');
  const target = schema().definitions[name];
  if (target === undefined) throw new Error(`schema has no definition ${name}`);
  return target;
}

function walk(node: JsonSchemaNode, value: unknown, path: string, out: SchemaViolation[]): void {
  const s = deref(node);

  if (s.enum !== undefined) {
    if (typeof value !== 'string' || !s.enum.includes(value)) {
      out.push({ path, message: `expected one of ${s.enum.join(' | ')}, got ${JSON.stringify(value)}` });
    }
    return;
  }
  if (s.const !== undefined && value !== s.const) {
    out.push({ path, message: `expected ${JSON.stringify(s.const)}, got ${JSON.stringify(value)}` });
    return;
  }

  switch (s.type) {
    case 'object': {
      if (typeof value !== 'object' || value === null || Array.isArray(value)) {
        out.push({ path, message: `expected object, got ${typeOf(value)}` });
        return;
      }
      const record = value as Record<string, unknown>;
      for (const key of s.required ?? []) {
        if (!(key in record)) out.push({ path: join2(path, key), message: 'required field is missing' });
      }
      if (s.additionalProperties === false && s.properties !== undefined) {
        for (const key of Object.keys(record)) {
          if (!(key in s.properties)) out.push({ path: join2(path, key), message: 'field is not in the schema' });
        }
      }
      for (const [key, child] of Object.entries(s.properties ?? {})) {
        if (key in record) walk(child, record[key], join2(path, key), out);
      }
      return;
    }
    case 'array': {
      if (!Array.isArray(value)) {
        out.push({ path, message: `expected array, got ${typeOf(value)}` });
        return;
      }
      if (s.items !== undefined) {
        value.forEach((item, i) => { walk(s.items as JsonSchemaNode, item, join2(path, String(i)), out); });
      }
      return;
    }
    case 'string':
      if (typeof value !== 'string') out.push({ path, message: `expected string, got ${typeOf(value)}` });
      return;
    case 'boolean':
      if (typeof value !== 'boolean') out.push({ path, message: `expected boolean, got ${typeOf(value)}` });
      return;
    default:
      return;
  }
}

function typeOf(value: unknown): string {
  if (value === null) return 'null';
  if (Array.isArray(value)) return 'array';
  return typeof value;
}

function join2(path: string, key: string): string {
  return path === '' ? key : `${path}/${key}`;
}

/**
 * Check a parsed document against one definition of the schema. Violations are reported, not
 * thrown: the console's whole purpose is to show a record that disagrees with itself, and a
 * validator that refused to render the fixture would be hiding the finding.
 */
export function validateAgainst<T>(definition: string, value: unknown): ValidationResult<T> {
  const violations: SchemaViolation[] = [];
  walk({ $ref: `#/definitions/${definition}` }, value, '', violations);
  return { value: value as T, violations };
}
