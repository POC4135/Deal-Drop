import type { ReactNode } from 'react';

export function TableCard({
  title,
  subtitle,
  columns,
  rows,
}: {
  title: string;
  subtitle: string;
  columns: string[];
  rows: ReactNode[][];
}) {
  return (
    <section className="panel overflow-hidden">
      <div className="border-b border-[var(--line)] px-6 py-5">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">{title}</p>
        <p className="mt-2 text-sm text-[var(--body)]">{subtitle}</p>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full text-left">
          <thead className="bg-[var(--panel-strong)] text-xs uppercase tracking-[0.16em] text-[var(--muted)]">
            <tr>
              {columns.map((column) => (
                <th key={column} className="px-6 py-4 font-semibold">
                  {column}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, index) => (
              <tr key={index} className="border-t border-[var(--line)] text-sm text-[var(--ink)]">
                {row.map((cell, cellIndex) => (
                  <td key={cellIndex} className="px-6 py-4 align-top">
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
