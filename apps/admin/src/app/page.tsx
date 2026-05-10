export default function HomePage() {
  return (
    <main className="min-h-screen bg-black text-white p-8">
      <div className="max-w-7xl mx-auto space-y-8">
        <header className="space-y-2">
          <h1 className="text-4xl font-bold">You-Sir Juan™</h1>
          <p className="text-zinc-400">
            Ready Play Administrative Dashboard
          </p>
        </header>

        <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
            <h2 className="text-sm uppercase text-zinc-500">Profile</h2>
            <p className="mt-3 text-2xl font-semibold">M1 8GB Light</p>
          </div>

          <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
            <h2 className="text-sm uppercase text-zinc-500">Models</h2>
            <p className="mt-3 text-2xl font-semibold">Ollama Ready</p>
          </div>

          <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
            <h2 className="text-sm uppercase text-zinc-500">Vector Memory</h2>
            <p className="mt-3 text-2xl font-semibold">Qdrant Online</p>
          </div>

          <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
            <h2 className="text-sm uppercase text-zinc-500">Skill Library</h2>
            <p className="mt-3 text-2xl font-semibold">Migration Active</p>
          </div>
        </section>

        <section className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
          <h2 className="text-xl font-semibold">Platform Status</h2>

          <div className="mt-6 space-y-3 text-zinc-300">
            <p>• Local-first sovereign AI infrastructure</p>
            <p>• Hardware-aware deployment profiles</p>
            <p>• Ready Play administrative runtime scaffold</p>
            <p>• Skill library integration in progress</p>
            <p>• Ethics and device sensor doctrine enabled</p>
          </div>
        </section>
      </div>
    </main>
  )
}
