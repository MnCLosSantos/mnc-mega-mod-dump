let container = document.getElementById("container");
let title = document.getElementById("title");
let message = document.getElementById("message");
let cooldownEl = document.getElementById("cooldown");
let cooldownTimer;

window.addEventListener("message", (event) => {
    const data = event.data;

    if (data.action === "selfCheck") {
        title.textContent = "ID Check Started";
        message.textContent = "You are checking nearby IDs.";
        container.classList.remove("hidden");

        let remaining = Math.floor(data.cooldown / 1000);
        clearInterval(cooldownTimer);
        cooldownEl.classList.remove("hidden");
        cooldownEl.textContent = `Cooldown: ${remaining}s`;

        cooldownTimer = setInterval(() => {
            remaining--;
            cooldownEl.textContent = `Cooldown: ${remaining}s`;
            if (remaining <= 0) {
                clearInterval(cooldownTimer);
                cooldownEl.classList.add("hidden");
                container.classList.add("hidden");
            }
        }, 1000);

    } else if (data.action === "otherCheck") {
        title.textContent = "Nearby ID Check";
        message.textContent = "Someone nearby is checking IDs.";
        cooldownEl.classList.add("hidden");
        container.classList.remove("hidden");

        setTimeout(() => {
            container.classList.add("hidden");
        }, 5000);

    } else if (data.action === "cooldown") {
        title.textContent = "Cooldown Active";
        message.textContent = `You must wait ${data.seconds}s before checking again.`;
        cooldownEl.classList.add("hidden");
        container.classList.remove("hidden");

        setTimeout(() => {
            container.classList.add("hidden");
        }, 3000);
    }
});
