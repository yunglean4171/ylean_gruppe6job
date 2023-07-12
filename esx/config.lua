Ylean = {}

Ylean.JobName = "gruppe6"

Ylean.Config = {
    vehicle_coords = vector4(-4.74, -670.57, 31.95, 187.08),
    vehicle_model = "stockade",

    job_guy_coords = vector4(0.11, -665.72, 31.34, 184.91),
    job_guy_model = "s_m_m_security_01"
}

Ylean.Salary = {
    amount = 10000,
    type = "cash" -- input "cash" or "bank"
}

Ylean.DeliveryPoints = { --add as many as you want :))
    {
        coords = vector4(147.12, -1045.02, 29.37, 252.97),
        delivered = false -- do not touch
    },
    {
        coords = vector4(-1211.24, -335.61, 37.78, 308.9),
        delivered = false -- do not touch
    }
}

Ylean.Locales = {
    main_blip_name = "Gruppe 6 Job",
    delivery_blip_name = "Delivery Point",
    start_job_label = "Start job",
    end_job_label ="Return vehicle",
    repair_vehicle_label = "Repair vehicle",
    get_cash_label = "Take out cash bag",
    job_in_progress = "Your job is currently in progress!",
    error = "Deliver one cash suitcase before taking out another one!",
    hint = "Press [E] to deliver cash",
    all_deliveries_completed = "All deliveries has been completed, return to base to return vehicle and get this bread",
    deliveries_status = "Deliveries completed: ",
    salary_received = "You've received salary of $",
    error2 = "Complete all deliveries to end your job!"
}