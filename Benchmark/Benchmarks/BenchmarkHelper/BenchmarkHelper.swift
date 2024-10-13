import Benchmark

package let defaultMetrics: [BenchmarkMetric] = [
    .cpuTotal,
    .mallocCountTotal,
    .instructions,
    .peakMemoryResident,
]

package let defaultConfiguration: Benchmark.Configuration = .init(
    metrics: defaultMetrics,
    scalingFactor: .kilo,
    maxDuration: .seconds(20),
    maxIterations: 10000
)
