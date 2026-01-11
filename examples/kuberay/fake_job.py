import ray
import time
import socket


ray.init(
    logging_config=ray.LoggingConfig(log_level="WARNING")
)

print("🚀 Ray Cluster Connected! Starting parallel processing...")


# by default, nump_cpus=1
@ray.remote(num_cpus=0.5)
def fake_job(index):
    # Simulate work (e.g., data processing) for 5 seconds
    time.sleep(5) 
    
    # Get the name of the pod/machine running this task
    host = socket.gethostname()
    return f"Task {index} processed on {host}"


# .remote() is non-blocking, so this sends 20 tasks to the scheduler immediately
print("   ... dispatching 20 tasks to workers ...")
start_time = time.time()
futures = [fake_job.remote(i) for i in range(20)]

# ray.get() blocks until all tasks are finished and returns the values
results = ray.get(futures)
duration = time.time() - start_time

print(f"\n✅ Finished processing {len(results)} tasks in {duration:.2f} seconds.")
print("--- Results ---")
for res in results:
    print(res)
