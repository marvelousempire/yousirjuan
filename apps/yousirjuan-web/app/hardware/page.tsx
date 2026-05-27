'use client';

import React from 'react';

import hardwareData from '../../../../hardware/imac-hardware-data.json';

interface HardwareItem {
  machine: string;
  category: string;
  spec: string;
  current: string;
  max: string;
  upgrade: string;
  recommended: string;
  price: string;
  status: string;
  notes: string;
}

const data: HardwareItem[] = hardwareData as HardwareItem[];

export default function HardwareReportPage() {
  const machines = ['2012 iMac', '2017 iMac'];

  return (
    <div className="min-h-screen bg-zinc-950 text-white p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-10">
          <h1 className="text-4xl font-semibold tracking-tight mb-2">Legacy iMac Hardware Report</h1>
          <p className="text-zinc-400 text-lg">Max-Out Project for Local AI Coding • Single Source of Truth: hardware/imac-hardware-data.json</p>
          <div className="mt-4 inline-flex items-center gap-2 rounded-full bg-emerald-950 px-4 py-1 text-sm text-emerald-400">
            Living Document • Auto-synced from JSON
          </div>
        </div>

        {/* Executive Summary */}
        <div className="mb-12 rounded-2xl border border-zinc-800 bg-zinc-900 p-8">
          <h2 className="text-2xl font-semibold mb-4">Executive Summary</h2>
          <p className="text-zinc-300 leading-relaxed">
            This report compiles all hardware specifications, upgrade paths, and current recommendations for the two 27-inch Intel iMacs in the Legacy iMac Max-Out Project. 
            The goal is to maximize both machines for the best possible private local AI coding experience (Ollama + Continue.dev) given their age and architectural limits.
          </p>
          <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div className="rounded-xl bg-zinc-950 p-4">
              <div className="font-medium text-emerald-400 mb-1">2012 iMac (Weaker)</div>
              <div>Maxed at 32GB RAM + SATA SSD + Sonoma via OCLP</div>
              <div className="text-xs text-zinc-500 mt-1">Target: 1.5B–3B models only</div>
            </div>
            <div className="rounded-xl bg-zinc-950 p-4">
              <div className="font-medium text-emerald-400 mb-1">2017 iMac (Stronger)</div>
              <div>64GB RAM + NVMe SSD upgrade path</div>
              <div className="text-xs text-zinc-500 mt-1">Target: Up to 7B models comfortably</div>
            </div>
          </div>
        </div>

        {/* 2012 iMac Section */}
        <div className="mb-12">
          <div className="flex items-center gap-3 mb-4">
            <h2 className="text-3xl font-semibold">Machine 1: Late 2012 27-inch iMac</h2>
            <span className="rounded-full bg-orange-950 px-3 py-1 text-xs text-orange-400">Needs Full Max-Out</span>
          </div>
          
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 text-zinc-400">
                <tr>
                  <th className="px-6 py-4 text-left font-medium">Category</th>
                  <th className="px-6 py-4 text-left font-medium">Current / Max</th>
                  <th className="px-6 py-4 text-left font-medium">Recommended Upgrade</th>
                  <th className="px-6 py-4 text-left font-medium">Est. Price (FL)</th>
                  <th className="px-6 py-4 text-left font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800 bg-zinc-950">
                {data.filter(d => d.machine === '2012 iMac').map((row, index) => (
                  <tr key={index} className="hover:bg-zinc-900/50">
                    <td className="px-6 py-4 font-medium text-white">{row.category}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.current} / {row.max}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.recommended}</td>
                    <td className="px-6 py-4 text-emerald-400 font-mono">{row.price}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-block rounded-full px-3 py-1 text-xs font-medium ${row.status === 'Maxed' ? 'bg-emerald-950 text-emerald-400' : 'bg-orange-950 text-orange-400'}`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* 2017 iMac Section */}
        <div className="mb-12">
          <div className="flex items-center gap-3 mb-4">
            <h2 className="text-3xl font-semibold">Machine 2: Mid 2017 27-inch iMac</h2>
            <span className="rounded-full bg-emerald-950 px-3 py-1 text-xs text-emerald-400">Strong Daily Driver</span>
          </div>
          
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 text-zinc-400">
                <tr>
                  <th className="px-6 py-4 text-left font-medium">Category</th>
                  <th className="px-6 py-4 text-left font-medium">Current / Max</th>
                  <th className="px-6 py-4 text-left font-medium">Recommended Upgrade</th>
                  <th className="px-6 py-4 text-left font-medium">Est. Price (FL)</th>
                  <th className="px-6 py-4 text-left font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800 bg-zinc-950">
                {data.filter(d => d.machine === '2017 iMac').map((row, index) => (
                  <tr key={index} className="hover:bg-zinc-900/50">
                    <td className="px-6 py-4 font-medium text-white">{row.category}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.current} / {row.max}</td>
                    <td className="px-6 py-4 text-zinc-300">{row.recommended}</td>
                    <td className="px-6 py-4 text-emerald-400 font-mono">{row.price}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-block rounded-full px-3 py-1 text-xs font-medium ${row.status === 'Maxed' || row.status === 'Good' ? 'bg-emerald-950 text-emerald-400' : 'bg-orange-950 text-orange-400'}`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="text-xs text-zinc-500 mt-8">
          Data sourced from hardware/imac-hardware-data.json • Last synced via hardware/sync-hardware-md.js
        </div>
      </div>
    </div>
  );
}
