'use client';
import React from 'react';
import cn from 'clsx';

type Props = {
  children: React.ReactNode;
  color?: 'green' | 'blue' | 'orange' | 'gray';
  onClose?: () => void;
};

export default function Chip({ children, color = 'gray', onClose }: Props) {
  const palette: Record<NonNullable<Props['color']>, string> = {
    green: 'bg-emerald-50 text-emerald-700',
    blue: 'bg-blue-50 text-blue-700',
    orange: 'bg-amber-50 text-amber-700',
    gray: 'bg-gray-100 text-gray-700',
  };
  return (
    <span className={cn('inline-flex items-center gap-2 rounded-xl px-3 py-1 text-sm', palette[color])}>
      {children}
      {onClose && (
        <button onClick={onClose} className="ml-1 rounded-md px-1 hover:bg-black/5" aria-label="remove">
          ×
        </button>
      )}
    </span>
  );
}
