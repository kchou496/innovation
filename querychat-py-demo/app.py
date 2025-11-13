from shiny import App, ui, render, reactive
from shinywidgets import output_widget, render_widget
import pandas as pd
from querychat import ui as querychat_ui, server as querychat_server, init as querychat_init
from chatlas import ChatBedrockAnthropic
import os
import subprocess

# Set AWS credentials
aws_creds = subprocess.run(
    ["aws", "configure", "export-credentials", "--format", "env"],
    capture_output=True,
    text=True
).stdout

for line in aws_creds.strip().split('\n'):
    line = line.strip()
    if not line:
        continue
    if line.startswith('export '):
        line = line[7:]
    if '=' in line:
        key, value = line.split('=', 1)
        os.environ[key] = value

os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'

# Function to create chat client
def use_bedrock(system_prompt: str):
    return ChatBedrockAnthropic(
        model="us.anthropic.claude-sonnet-4-20250514-v1:0",
        system_prompt=system_prompt
    )

# App UI
app_ui = ui.page_fluid(
    ui.output_ui("dynamic_ui")
)

def server(input, output, session):
    uploaded_data = reactive.Value(None)
    app_started = reactive.Value(False)
    querychat_config = reactive.Value(None)
    
    @output
    @render.ui
    def dynamic_ui():
        if not app_started():
            return ui.div(
                {"style": "max-width: 600px; margin: 100px auto; text-align: center;"},
                ui.h1("QueryChat - Custom File Upload"),
                ui.br(),
                ui.panel_well(
                    ui.h3("Upload Your Data"),
                    ui.input_file(
                        "file_upload",
                        "Choose a CSV file to get started",
                        accept=[".csv"],
                        width="100%"
                    ),
                    ui.br(),
                    ui.input_action_button(
                        "start_app",
                        "Start App",
                        class_="btn-primary btn-lg"
                    )
                )
            )
        else:
            return ui.page_sidebar(
                ui.sidebar(
                    querychat_ui("chat")
                ),
                ui.card(
                    ui.card_header("Data Table"),
                    ui.output_data_frame("data_table")
                ),
                title="QueryChat - Custom File Upload"
            )
    
    @reactive.Effect
    @reactive.event(input.file_upload)
    def handle_upload():
        if input.file_upload():
            try:
                file_info = input.file_upload()[0]
                df = pd.read_csv(file_info["datapath"])
                uploaded_data.set(df)
                ui.notification_show("File uploaded! Click 'Start App' to continue.", type="message")
            except Exception as e:
                ui.notification_show(f"Error loading file: {str(e)}", type="error")
    
    @reactive.Effect
    @reactive.event(input.start_app)
    def start_application():
        if uploaded_data() is not None:
            try:
                # Initialize querychat config with client parameter (as a function)
                config = querychat_init(
                    uploaded_data(), 
                    table_name="uploaded_data",
                    client=use_bedrock,  # Pass the function, not an instance
                    greeting="Ask me questions about your uploaded data"
                )
                querychat_config.set(config)
                
                # Initialize querychat server with just the config
                querychat_server("chat", config)
                
                app_started.set(True)
                ui.notification_show("App started successfully!", type="message")
            except Exception as e:
                ui.notification_show(f"Error starting app: {str(e)}", type="error")
                print(f"Full error: {e}")  # Debug info
    
    @output
    @render.data_frame
    def data_table():
        if uploaded_data() is not None:
            return uploaded_data()
        return pd.DataFrame()

app = App(app_ui, server)