#!/usr/bin/env python3

import os
import json
import docker
import argparse
import logging
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ChallengeManager:
    def __init__(self, docker_host: str = "tcp://localhost:2376", 
                 cert_path: str = "/etc/docker/certs"):
        """Initialize the challenge manager.
        
        Args:
            docker_host: Docker daemon host address
            cert_path: Path to Docker TLS certificates
        """
        self.client = docker.DockerClient(
            base_url=docker_host,
            tls=docker.tls.TLSConfig(
                client_cert=(f"{cert_path}/client/cert.pem", 
                           f"{cert_path}/client/key.pem"),
                ca_cert=f"{cert_path}/ca/cert.pem",
                verify=True
            )
        )
        self.challenges: Dict[str, docker.models.containers.Container] = {}

    def load_challenge(self, challenge_dir: str) -> Optional[Dict]:
        """Load challenge configuration from a directory.
        
        Args:
            challenge_dir: Path to challenge directory
            
        Returns:
            Challenge configuration dict or None if invalid
        """
        try:
            with open(os.path.join(challenge_dir, "challenge.json")) as f:
                config = json.load(f)
                
            # Validate required fields
            required = ["name", "category", "type", "value", "description"]
            if not all(field in config for field in required):
                logger.error(f"Missing required fields in {challenge_dir}/challenge.json")
                return None
                
            return config
            
        except (json.JSONDecodeError, FileNotFoundError) as e:
            logger.error(f"Error loading challenge config: {e}")
            return None

    def build_challenge(self, challenge_dir: str, config: Dict) -> bool:
        """Build a challenge container.
        
        Args:
            challenge_dir: Path to challenge directory
            config: Challenge configuration
            
        Returns:
            True if build successful, False otherwise
        """
        try:
            # Build the container
            image, _ = self.client.images.build(
                path=challenge_dir,
                tag=f"ctf-{config['name'].lower()}:latest",
                rm=True
            )
            
            logger.info(f"Built challenge container: {config['name']}")
            return True
            
        except docker.errors.BuildError as e:
            logger.error(f"Error building challenge container: {e}")
            return False

    def start_challenge(self, config: Dict) -> bool:
        """Start a challenge container.
        
        Args:
            config: Challenge configuration
            
        Returns:
            True if start successful, False otherwise
        """
        try:
            # Start the container
            container = self.client.containers.run(
                image=f"ctf-{config['name'].lower()}:latest",
                name=f"ctf-{config['name'].lower()}",
                detach=True,
                network="ctf-network",
                restart_policy={"Name": "unless-stopped"},
                ports={f"{port}/tcp": None for port in config.get("ports", [])}
            )
            
            self.challenges[config["name"]] = container
            logger.info(f"Started challenge container: {config['name']}")
            return True
            
        except docker.errors.APIError as e:
            logger.error(f"Error starting challenge container: {e}")
            return False

    def stop_challenge(self, name: str) -> bool:
        """Stop a challenge container.
        
        Args:
            name: Challenge name
            
        Returns:
            True if stop successful, False otherwise
        """
        try:
            if name in self.challenges:
                container = self.challenges[name]
                container.stop()
                container.remove()
                del self.challenges[name]
                logger.info(f"Stopped challenge container: {name}")
                return True
            return False
            
        except docker.errors.APIError as e:
            logger.error(f"Error stopping challenge container: {e}")
            return False

    def cleanup(self):
        """Stop and remove all challenge containers."""
        for name in list(self.challenges.keys()):
            self.stop_challenge(name)

    def deploy_challenges(self, challenges_dir: str = "challenges"):
        """Deploy all challenges from the challenges directory.
        
        Args:
            challenges_dir: Path to challenges directory
        """
        # Create network if it doesn't exist
        try:
            self.client.networks.create("ctf-network", driver="bridge")
        except docker.errors.APIError:
            pass

        # Process each challenge directory
        for challenge_name in os.listdir(challenges_dir):
            challenge_dir = os.path.join(challenges_dir, challenge_name)
            if not os.path.isdir(challenge_dir):
                continue

            # Load and validate challenge config
            config = self.load_challenge(challenge_dir)
            if not config:
                continue

            # Build and start challenge
            if self.build_challenge(challenge_dir, config):
                self.start_challenge(config)

def main():
    parser = argparse.ArgumentParser(description="CTF Challenge Manager")
    parser.add_argument("--cleanup", action="store_true", 
                       help="Stop and remove all challenge containers")
    parser.add_argument("--docker-host", default="tcp://localhost:2376",
                       help="Docker daemon host address")
    parser.add_argument("--cert-path", default="/etc/docker/certs",
                       help="Path to Docker TLS certificates")
    args = parser.parse_args()

    manager = ChallengeManager(args.docker_host, args.cert_path)

    if args.cleanup:
        manager.cleanup()
    else:
        manager.deploy_challenges()

if __name__ == "__main__":
    main() 