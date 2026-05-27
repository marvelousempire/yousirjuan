import HardwareTable from '@/components/HardwareTable';

export default function HardwareDemoPage() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-semibold tracking-tight text-gray-900">iMac Max-Out Hardware Inventory</h1>
          <p className="mt-2 text-gray-600 max-w-2xl">
            Living table for the Legacy iMac Max-Out Project. Data sourced from <code>hardware/imac-hardware-data.json</code>.
            Use filters, search, and column sorting to explore upgrade paths for both machines.
          </p>
        </div>

        <HardwareTable />

        <div className="mt-8 text-sm text-gray-500">
          This demo page is embedded in the yousirjuan-web app. The same component can be dropped into the admin dashboard or docs site.
        </div>
      </div>
    </div>
  );
}
