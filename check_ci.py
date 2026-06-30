import urllib.request, json, os
REPO = 'lion77542/AstrBot-Android-LLOneBot'
with open(r'C:\Users\dlamd\.gh_token','r') as f:
    TOKEN=f.read...nURL = f'https://api.github.com/repos/{REPO}/actions/runs/28462691202'
req = urllib.request.Request(URL, headers={'User-Agent': 'Hermes-Agent', 'Authorization': f'token {TOKEN}'})
with urllib.request.urlopen(req, timeout=15) as resp:
    data = json.loads(resp.read())
    jobs_url = data.get('jobs_url')
    if jobs_url:
        jreq = urllib.request.Request(jobs_url, headers={'User-Agent': 'Hermes-Agent', 'Authorization': f'token {TOKEN}'})
        with urllib.request.urlopen(jreq, timeout=15) as jresp:
            jdata = json.loads(jresp.read())
            for job in jdata.get('jobs', []):
                print(f"job={job['name']} status={job.get('status')} conclusion={job.get('conclusion')}")
                for step in job.get('steps', []):
                    print(f"  step={step['name']} status={step.get('status')} conclusion={step.get('conclusion')}")
                    if step.get('conclusion') == 'failure':
                        print(f"    FAILED STEP: {step.get('name')}")
