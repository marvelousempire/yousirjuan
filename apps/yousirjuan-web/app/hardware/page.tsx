'use client';

import React from 'react';

import hardwareData from '../../../../hardware/imac-hardware-data.json';

interface HardwareItem {
  id: string;
  machine: string;
  category: string;
  specification: string;
  maxRecommended: string;
  upgradePath: string;
  recommendedPart: string;
  price: string;
  status: string;
  notes: string;
}

const data: HardwareItem[] = hardwareData as HardwareItem[];

export default function HardwareReportPage() {
  return (
    <div className="min-h-screen bg-zinc-950 text-white p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-10">
          <h1 className="text-4xl font-semibold tracking-tight mb-2">Legacy iMac Hardware Report</h1>
          <p className="text-zinc-400 text-lg">Max-Out Project for Local AI Coding • Single Source of Truth</p>
          <div className="mt-4 inline-flex items-center gap-2 rounded-full bg-emerald-950 px-4 py-1 text-sm text-emerald-400">
            hardware/imac-hardware-data.json • Living Document
          </div>
        </div>

        {/* Executive Summary */}
        <div className="mb-12 rounded-2xl border border-zinc-800 bg-zinc-900 p-8">
          <h2 className="text-2xl font-semibold mb-4">Executive Summary</h2>
          <p className="text-zinc-300 leading-relaxed max-w-3xl">
            Complete hardware inventory and upgrade recommendations for both 27-inch Intel iMacs. 
            Goal: Maximize both machines for private local AI coding (Ollama + Continue.dev).
          </p>
          <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="rounded-xl bg-zinc-950 p-5 border border-zinc-800">
              <div className="text-emerald-400 text-sm font-medium mb-1">2012 iMac</div>
              <div className="text-lg">32GB RAM + SATA SSD + OCLP → Sonoma</div>
              <div className="text-xs text-zinc-500 mt-2">Target: 1.5B–3B models only</div>
            </div>
            <div className="rounded-xl bg-zinc-950 p-5 border border-zinc-800">
              <div className="text-emerald-400 text-sm font-medium mb-1">2017 iMac (Daily Driver)</div>
              <div className="text-lg">64GB RAM + NVMe upgrade path</div>
              <div className="text-xs text-zinc-500 mt-2">Target: Up to 7B models</div>
            </div>
          </div>
        </div>

        {/* 2012 iMac */}
        <div className="mb-14">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-3xl font-semibold">Machine 1: Late 2012 27-inch iMac</h2>
            <span className="text-xs px-3 py-1 rounded-full bg-orange-950 text-orange-400">Needs Full Max-Out</span>
          </div>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800 bg-zinc-950">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-zinc-800 bg-zinc-900 text-zinc-400">
                  <th className="px-6 py-4 text-left font-medium">Category</th>
                  <th className="px-6 py-4 text-left font-medium">Current → Max</th>
                  <th className="px-6 py-4 text-left font-medium">Recommended Part</th>
                  <th className="px-6 py-4 text-left font-medium">Price (FL)</th>
                  <th className="px-6 py-4 text-left font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800">
                {data.filter(d => d.machine === '2012 iMac').map((row) => (
                  <tr key={row.id} className="hover:bg-zinc-900/60">
                    <td className="px-6 py-4 font-medium text-white">{row.category}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.specification} → {row.maxRecommended}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.recommendedPart}</td>
                    <td className="px-6 py-4 font-mono text-emerald-400">{row.price}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${row.status === 'Maxed' ? 'bg-emerald-950 text-emerald-400' : row.status === 'Needs Upgrade' ? 'bg-orange-950 text-orange-400' : 'bg-zinc-800 text-zinc-400'}`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* 2017 iMac */}
        <div className="mb-14">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-3xl font-semibold">Machine 2: Mid 2017 27-inch iMac</h2>
            <span className="text-xs px-3 py-1 rounded-full bg-emerald-950 text-emerald-400">Strong Daily Driver</span>
          </div>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800 bg-zinc-950">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-zinc-800 bg-zinc-900 text-zinc-400">
                  <th className="px-6 py-4 text-left font-medium">Category</th>
                  <th className="px-6 py-4 text-left font-medium">Current → Max</th>
                  <th className="px-6 py-4 text-left font-medium">Recommended Part</th>
                  <th className="px-6 py-4 text-left font-medium">Price (FL)</th>
                  <th className="px-6 py-4 text-left font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800">
                {data.filter(d => d.machine === '2017 iMac').map((row) => (
                  <tr key={row.id} className="hover:bg-zinc-900/60">
                    <td className="px-6 py-4 font-medium text-white">{row.category}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.specification} → {row.maxRecommended}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.recommendedPart}</td>
                    <td className="px-6 py-4 font-mono text-emerald-400">{row.price}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${row.status === 'Maxed' || row.status === 'Good' || row.status === 'Recommended' ? 'bg-emerald-950 text-emerald-400' : 'bg-orange-950 text-orange-400'}`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="text-center text-xs text-zinc-500 mt-12">
          Data sourced from <span className="font-mono text-zinc-400">hardware/imac-hardware-data.json</span> • Regenerated via sync script
        </div>
      </div>
    </div>
  );
}
