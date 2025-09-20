import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="incidents"
export default class extends Controller {
  connect() {
    console.log("Incidents controller connected!")
    console.log("Turbo Streams will handle real-time updates automatically")
  }

  disconnect() {
    console.log("Incidents controller disconnecting...")
  }

  updateStats(data) {
    console.log("🔄 Updating stats:", data)
    const totalElement = document.getElementById("total-count")
    const unresolvedElement = document.getElementById("unresolved-count")
    
    if (totalElement) {
      totalElement.textContent = data.total_count
      console.log("✅ Updated total count to:", data.total_count)
    } else {
      console.log("❌ Could not find total-count element")
    }
    
    if (unresolvedElement) {
      unresolvedElement.textContent = data.unresolved_count
      console.log("✅ Updated unresolved count to:", data.unresolved_count)
    } else {
      console.log("❌ Could not find unresolved-count element")
    }
  }
}
