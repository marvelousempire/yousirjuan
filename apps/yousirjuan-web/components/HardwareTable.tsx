'use client';

import React, { useState, useMemo } from 'react';
import hardwareDataJson from '../../../../hardware/imac-hardware-data.json';

// Type definitions for living table
export interface HardwareRow {
  id: string;
  machine: '2012 iMac' | '2017 iMac';
  category: string;
  specification: string;
  maxRecommended: string;
  upgradePath: string;
  recommendedPart: string;
  price: string;
  status: 'Maxed' | 'Needs Upgrade' | 'Verify' | 'Limited' | 'Recommended' | 'Good';
  notes: string;
}

// Import from shared single-source-of-truth JSON
const hardwareData: HardwareRow[] = hardwareDataJson as HardwareRow[];

const statusColors: Record<HardwareRow['status'], string> = {
  'Maxed': 'bg-green-100 text-green-800 border-green-200',
  'Needs Upgrade': 'bg-amber-100 text-amber-800 border-amber-200',
  'Verify': 'bg-blue-100 text-blue-800 border-blue-200',
  'Limited': 'bg-red-100 text-red-800 border-red-200',
  'Recommended': 'bg-emerald-100 text-emerald-800 border-emerald-200',
  'Good': 'bg-sky-100 text-sky-800 border-sky-200',
};

const categories = ['All', ...Array.from(new Set(hardwareData.map(row => row.category)))];

export default function HardwareTable() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedMachine, setSelectedMachine] = useState<'All' | '2012 iMac' | '2017 iMac'>('All');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [sortConfig, setSortConfig] = useState<{ key: keyof HardwareRow; direction: 'asc' | 'desc' }>({
    key: 'machine',
    direction: 'asc',
  });

  const filteredAndSortedData = useMemo(() => {
    let result = [...hardwareData];

    // Filter by machine
    if (selectedMachine !== 'All') {
      result = result.filter(row => row.machine === selectedMachine);
    }

    // Filter by category
    if (selectedCategory !== 'All') {
      result = result.filter(row => row.category === selectedCategory);
    }

    // Filter by search
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      result = result.filter(row =>
        Object.values(row).some(value =>
          String(value).toLowerCase().includes(term)
        )
      );
    }

    // Sort
    result.sort((a, b) => {
      const aValue = a[sortConfig.key];
      const bValue = b[sortConfig.key];

      if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortConfig.direction === 'asc' ? 'asc' ? -1 : 1 : 0;
      return 0;
    });

    return result;
  }, [searchTerm, selectedMachine, selectedCategory, sortConfig]);

  const handleSort = (key: keyof HardwareRow) => {
    setSortConfig(current => ({
      key,
      direction: current.key === key && current.direction === 'asc' ? 'desc' : 'asc',
    }));
  };

  const getSortIcon = (key: keyof HardwareRow) => {
    if (sortConfig.key !== key) return '↕';
    return sortConfig.direction === 'asc' ? '↑' : '↓';
  };

  return (
    <div className="w-full space-y-4">
      {/* Controls */}
      <div className="flex flex-col md:flex-row gap-3 items-start md:items-center justify-between bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
          {/* Search */}
          <div className="relative flex-1 min-w-[220px]">
            <input
              type="text"
              placeholder="Search specs, parts, notes..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <div className="absolute left-3.5 top-3 text-gray-400">🔍</div>
          </div>

          {/* Machine Filter */}
          <select
            value={selectedMachine}
            onChange={(e) => setSelectedMachine(e.target.value as any)}
            className="px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
          >
            <option value="All">Both Machines</option>
            <option value="2012 iMac">2012 iMac only</option>
            <option value="2017 iMac">2017 iMac only</option>
          </select>

          {/* Category Filter */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
          >
            {categories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>
        </div>

        <div className="text-xs text-gray-500 font-mono">
          {filteredAndSortedData.length} / {hardwareData.length} rows
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto rounded-xl border border-gray-200 shadow-sm bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {(['machine', 'category', 'specification', 'maxRecommended', 'recommendedPart', 'price', 'status', 'notes'] as const).map((key) => (
                <th
                  key={key}
                  onClick={() => handleSort(key)}
                  className="px-4 py-3 text-left font-semibold text-gray-700 cursor-pointer hover:bg-gray-100 transition-colors select-none whitespace-nowrap"
                >
                  <div className="flex items-center gap-1.5">
                    {key === 'maxRecommended' ? 'Max / Recommended' : 
                     key === 'recommendedPart' ? 'Recommended Part' : 
                     key.charAt(0).toUpperCase() + key.slice(1)}
                    <span className="text-gray-400 text-xs">{getSortIcon(key)}</span>
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filteredAndSortedData.length > 0 ? (
              filteredAndSortedData.map((row) => (
                <tr key={row.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3 font-medium text-gray-900 whitespace-nowrap">
                    {row.machine}
                  </td>
                  <td className="px-4 py-3 text-gray-600 whitespace-nowrap">{row.category}</td>
                  <td className="px-4 py-3 text-gray-700 max-w-[220px]">{row.specification}</td>
                  <td className="px-4 py-3 text-gray-600 max-w-[180px]">{row.maxRecommended}</td>
                  <td className="px-4 py-3 text-gray-700 max-w-[260px] text-[13px]">{row.recommendedPart}</td>
                  <td className="px-4 py-3 font-mono text-xs text-gray-600 whitespace-nowrap">{row.price}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${statusColors[row.status]}`}>
                      {row.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 text-xs max-w-[240px]">{row.notes}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-gray-500">
                  No matching hardware entries found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Footer / Legend */}
      <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-gray-500 px-1">
        <div><span className="font-medium">Living Table:</span> Single source of truth is <code>hardware/imac-hardware-data.json</code>. Update JSON → Markdown docs + this interactive table stay in sync.</div>
        <div className="hidden md:block">• Click column headers to sort</div>
        <div>• Filter by machine or category</div>
      </div>
    </div>
  );
}
