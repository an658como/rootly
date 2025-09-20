import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Connects to data-controller="incidents"
export default class extends Controller {
  connect() {
    console.log("Incidents controller connected!")
    
    this.consumer = createConsumer()
    console.log("ActionCable consumer created:", this.consumer)
    
    this.subscription = this.consumer.subscriptions.create("IncidentsChannel", {
      connected() {
        console.log("✅ Connected to IncidentsChannel!")
      },
      
      disconnected() {
        console.log("❌ Disconnected from IncidentsChannel")
      },
      
      received(data) {
        console.log("📨 Received data:", data)
        if (data.type === "stats_update") {
          // Call the parent controller's method
          const controller = document.querySelector('[data-controller="incidents"]')
          if (controller && controller.stimulusController) {
            controller.stimulusController.updateStats(data)
          } else {
            // Fallback: direct DOM manipulation
            const totalElement = document.getElementById("total-count")
            const unresolvedElement = document.getElementById("unresolved-count")
            
            if (totalElement) totalElement.textContent = data.total_count
            if (unresolvedElement) unresolvedElement.textContent = data.unresolved_count
          }
        }
      }
    })
    
    // Store reference to this controller for ActionCable callbacks
    this.element.stimulusController = this
  }

  disconnect() {
    console.log("Incidents controller disconnecting...")
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
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
