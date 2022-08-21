FROM python:3.9-slim-bullseye

WORKDIR /app

COPY . .

RUN pip3 install -r requirements.txt

EXPOSE 5000

CMD [ "python3", "-m" , "flask", "-A", "application", "run", "--host=0.0.0.0"]
