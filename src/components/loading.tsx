'use client';

import { LoaderCircle } from 'lucide-react';

export function Loading() {
  return (
    <div className="flex items-center justify-center h-screen">
      <LoaderCircle className="animate-spin h-12 w-12" />
    </div>
  );
}
