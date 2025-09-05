'use client';
import React from 'react';
import cn from 'clsx';

type Props = React.InputHTMLAttributes<HTMLInputElement> & {
  left?: React.ReactNode;
  right?: React.ReactNode;
};

export default function Input({ className, left, right, ...props }: Props) {
  return (
    <div className={cn('flex items-center gap-2 rounded-2xl border bg-white px-3', className)}>
      {left && <span className="shrink-0 text-gray-500">{left}</span>}
      <input
        className="w-full h-10 outline-none bg-transparent placeholder:text-gray-400"
        {...props}
      />
      {right && <span className="shrink-0 text-gray-400">{right}</span>}
    </div>
  );
}
