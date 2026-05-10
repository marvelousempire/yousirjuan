import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    status: 'ok',
    platform: 'You-Sir Juan',
    dashboard: 'Ready Play Administrative Dashboard',
    services: {
      admin: 'online',
      ollama: 'expected-local',
      qdrant: 'expected-local',
      openWebUI: 'expected-local'
    },
    runtime: {
      mode: 'development',
      maturity: 'early-stage-runtime-platform'
    }
  })
}
